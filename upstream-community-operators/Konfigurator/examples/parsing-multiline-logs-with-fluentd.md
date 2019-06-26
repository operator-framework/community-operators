# Parsings multiline logs with Fluentd

Every application has its own log format which means that every time a new application comes in, you have to add a new regex format to your fluentd configuration for that app manually and restart fluentd so it can parse that application's logs.

This is one of the perfect examples where konfigurator can be of use.

## Pre-Requisites

- Kubernetes Cluster (1.8.7 or higher)
- Fluentd (1.0 or higher)
- Konfigurator
- Fluentd plugins (slack and concat)

If you don't have konfigurator running, follow the guide on the [readme](https://www.github.com/stakater/Konfigurator/tree/master/README.md) to deploy it.

### Fluentd plugins

This example requires you to have 2 fluentd plugin installed before you can proceed.

- [fluent-plugin-concat](https://github.com/fluent-plugins-nursery/fluent-plugin-concat) (Used for multiline logs)
- [fluent-plugin-slack](https://github.com/sowawa/fluent-plugin-slack) (Used for sending slack notifications)

Once you have installed the plugins mentioned above, you can proceed to the next step.

## Setting up Fluentd

First of all, you need to move your existing config to `KonfiguratorTemplate`. Lets say you have your config in a ConfigMap as follows:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd
data:
  fluent.conf: |
    # Read kubernetes logs
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/es-containers.log.pos
      time_format %Y-%m-%dT%H:%M:%S.%N
      tag kubernetes.*
      format json
      read_from_head true
    </source>

    <filter kubernetes.var.log.containers.**.log>
      @type kubernetes_metadata
    </filter>

    <match **>
      @type stdout
    </match>
```

And you've mounted the above ConfigMap to fluentd's container at `/etc/fluentd/conf`.

In order to switch to `KonfiguratorTemplate` you just have to specify a bit more properties apart from fluent.conf file. Lets see an example of such a resource below:

```yaml
apiVersion: konfigurator.stakater.com/v1alpha1
kind: KonfiguratorTemplate
metadata:
  name: fluentd
spec:
  renderTarget: ConfigMap
  app:
    name: fluentd
    kind: DaemonSet
    volumeMounts:
    - mountPath: /fluentd/etc/conf
      container: fluentd
  templates:
    fluent.conf: |
      # Read kubernetes logs
      <source>
        @type tail
        path /var/log/containers/*.log
        pos_file /var/log/es-containers.log.pos
        time_format %Y-%m-%dT%H:%M:%S.%N
        tag kubernetes.*
        format json
        read_from_head true
      </source>

      <filter kubernetes.var.log.containers.**.log>
        @type kubernetes_metadata
      </filter>

      <match **>
        @type stdout
      </match>
```

More detailed information about the CRD properties are [here](https://www.github.com/stakater/Konfigurator/tree/master/docs/konfigurator-template.md).

Once you've done that, remove the volume mounts for the old ConfigMap since Konfigurator will automatically mount the rendered config to fluentd pods.

Re-deploy fluentd with the changes done above and you should see fluentd running similar to how it was running before.

Now before we move towards passing data from apps to fluentd configuration, lets define a structure which we will use to pass in app specific fluentd configuration. For this example we will use the following:

```json
[
  {
    "containers":
    [
      {
        "expressionFirstLine": "starting regex",
        "expression": "full regex",
        "timeFormat": "time format",
        "containerName": "container-name"
      }
    ],
    "notifications": {
      "slack": {
        "webhookURL": "https://google.com",
        "channelName": "dev-notifications"
      }
    }
  }
]

```

Let's explain few of the properties that are used above:

### expressionFirstLine

It is the regex used to concatenate logs that are split up into multiple lines.

### expression

It is the regex used for parsing internal log of the application.

### containerName

This is useful when pods have multiple containers running inside them and have different log formats. So it is necessary to specify the `containerName` if there's more than 1 pod, to ensure that the parser only parses that container's logs and not the others.

### timeFormat

Fluentd parser needs a valid time format for the logs it is parsing. It can be different for every app and can be based on the logging framework you're using for your app. Fluentd's internal time format validator is `strftime`, a popular ruby time parsing library. There's a handy tool that lets your create your own strftime compatible time format for your app logs here which you can use: [https://www.foragoodstrftime.com](https://www.foragoodstrftime.com)

### webhookURL

The slack webhook URL where you want to send slack notifications in case of an error log.

### channelName

The channel name on slack that will receive the error logs.

## Setting up apps that log stuff

We will be passing the above json configuration in an annotation named `fluentdConfiguration`. Let's say you have a deployment, so after adding the annotation, it will look similar to following:

```yaml
apiVersion: v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    fluentdConfiguration: >
      [
        {
          "containers":
          [
            {
              "expressionFirstLine": "starting regex",
              "expression": "full regex",
              "timeFormat": "time format",
              "containerName": "container-name"
            }
          ],
          "notifications": {
            "slack": {
              "webhookURL": "https://google.com",
              "channelName": "dev-notifications"
            }
          }
        }
      ]
spec:
  template:
    spec:
      containers:
        - name: app
          image: yourorg/your-image
```

Re-deploy the app after making these changes. That was the only thing needed to do at the app's side. 

***Note:*** For every app that you want to parse logs of, including notifications, you need to add the annotation as explained above to its `Deployment`, `DaemonSet` or `StatefulSet`.

## Config Template for fluentd

Now that we have the app specific information bound to the app, lets create a config template that fetches the values from these apps and populates a correct fluentd config. For this example, here's the complete templated configuration that caters multiline logs as well as slack notifications:

```html
# Read kubernetes logs
<source>
    @type tail
    path /var/log/containers/*.log
    pos_file /var/log/es-containers.log.pos
    time_format %Y-%m-%dT%H:%M:%S.%N
    tag kubernetes.*
    format json
    read_from_head true
</source>

<filter kubernetes.var.log.containers.**.log>
    @type kubernetes_metadata
</filter>

# Workaround until fluent-slack-plugin adds support for nested values
<filter kubernetes.var.log.containers.**.log>
    @type record_transformer
    enable_ruby
    <record>
        kubernetes_pod_name ${record["kubernetes"]["pod_name"]}
        kubernetes_namespace_name ${record["kubernetes"]["namespace_name"]}
    </record>
</filter>

# Get distinct pods per application
{{- $podsWithAnnotations := whereExist .Pods "ObjectMeta.Annotations.fluentdConfiguration" -}}
{{- $distinctPods := distinctPodsByOwner $podsWithAnnotations -}}

# Create concat filters for supporting multiline
{{- range $pod := $distinctPods -}}
    {{- $config := first (parseJson $pod.ObjectMeta.Annotations.fluentdConfiguration) }}

    {{- range $containerConfig := $config.containers }}
        {{- if (len $pod.Spec.Containers) eq 1 }}
<filter kubernetes.var.log.containers.{{ (index $pod.ObjectMeta.OwnerReferences 0).Name }}**_{{ $pod.ObjectMeta.Namespace }}_{{ (index $pod.Spec.Containers 0).Name }}**.log>
        {{- else }}
<filter kubernetes.var.log.containers.{{ (index $pod.ObjectMeta.OwnerReferences 0).Name }}**_{{ $pod.ObjectMeta.Namespace }}_{{ $containerConfig.containerName }}**.log>
        {{- end }}
    @type concat
    key log
    multiline_start_regexp {{ $containerConfig.expressionFirstLine }}
    flush_interval 5s
    timeout_label @LOGS
</filter>
    {{- end }}
{{- end }}

# Relabel all logs to ensure timeout logs are treated as normal logs and not ignored
<match **>
    @type relabel
    @label @LOGS
</match>

<label @LOGS>
    # Create regexp filters for parsing internal logs of applications
    {{- range $pod := $distinctPods -}}
        {{- $config := first (parseJson $pod.ObjectMeta.Annotations.fluentdConfiguration) }}

        {{- range $containerConfig := $config.containers }}
            {{- if (len $pod.Spec.Containers) eq 1 }}
    <filter kubernetes.var.log.containers.{{ (index $pod.ObjectMeta.OwnerReferences 0).Name }}**_{{ $pod.ObjectMeta.Namespace }}_{{ (index $pod.Spec.Containers 0).Name }}**.log>
            {{- else }}
    <filter kubernetes.var.log.containers.{{ (index $pod.ObjectMeta.OwnerReferences 0).Name }}**_{{ $pod.ObjectMeta.Namespace }}_{{ $containerConfig.containerName }}**.log>
            {{- end }}
        @type parser
        key_name log
        reserve_data true
        <parse>
            @type regexp
            expression {{ $containerConfig.expression }}
            time_format {{ $containerConfig.timeFormat }}
        </parse>
    </filter>
        {{- end }}
    {{- end }}

    # Send parsed logs to both output and notification labels
    <match **>
        @type copy
        deep_copy true
        # If one store raises an error, it ignores other stores. So adding `ignore_error` ensures that the log will be sent to all stores regardless of the error 
        <store ignore_error>
            @type relabel
            @label @NOTIFICATION
        </store>
        <store ignore_error>
            @type relabel
            @label @OUTPUT
        </store>
    </match>
</label>

<label @OUTPUT>
    # Send logs to Stdout
    <match **>
        @type stdout
    </match>
</label>

<label @NOTIFICATION>
    # Filter ERROR level logs
    <filter **>
        @type grep
        <regexp>
            key level
            pattern (ERROR|error|Error|^E[0-9]{4})
        </regexp>
    </filter>

    # Create slack notification matchers for sending error notifications per app
    {{- range $pod := $distinctPods -}}
        {{- $config := first (parseJson $pod.ObjectMeta.Annotations.fluentdConfiguration) }}
        {{- if $config.notifications }}
    <match kubernetes.var.log.containers.{{ (index $pod.ObjectMeta.OwnerReferences 0).Name }}**_{{ $pod.ObjectMeta.Namespace }}_**.log>
        @type copy
        {{- if $config.notifications.slack }}
        <store ignore_error>
            @type slack
            webhook_url {{ $config.notifications.slack.webhookURL }}
            channel {{ $config.notifications.slack.channelName }}
            username fluentd
            icon_url https://raw.githubusercontent.com/fluent/fluentd-docs/master/public/logo/Fluentd_square.png
            flush_interval 15s
            parse full
            color danger
            link_names false
            title_keys level
            title %s log
            message_keys level,timestamp,kubernetes_pod_name,kubernetes_namespace_name,message
            message *Level* %s *Time* %s *Pod* %s *Namespace* %s *Message* %s
            time_key timestamp
        </store>
        {{- end }}
    </match>
        {{- end }}
    {{- end }}
</label>

```

There's a lot going on in this config:

- First, all the pods having the annotation `fluentdConfiguration` are fetched
- Then pods are filtered based on their owners so that there's only 1 pod left per app
- The first loop creates concat filters for multiline support which use `expressionFirstLine` for line detection
- The second loop creates parser filters which parse the inner logs based on regular expression provided in `expression` property
- Then all the logs are duplicated and sent to 2 separate destinations
- One is `stdout` and the other one is `slack`

Okay so replace the `fluent.conf` template in `KonfiguratorTemplate` with the above one. Once done, re deploy fluentd and Konfigurator will update the generated config with the new one which will contain app specific filters and matches.

Now if you have proper levels in logs, and the regexes and timestamp provided are correct, you will receive slack notifications on error logs. You can easily change the level on which the logs will be sent to slack by modifying the following block in template:

```html
# Filter ERROR level logs
<filter **>
    @type grep
    <regexp>
        key level
        pattern (ERROR|error|Error|^E[0-9]{4})
    </regexp>
</filter>
```

You can find commonly used regexes and timestamps [here](https://github.com/stakater/RegexHub).
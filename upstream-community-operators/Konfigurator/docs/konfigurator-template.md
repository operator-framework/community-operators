# KonfiguratorTemplate

The operator has a CRD named `KonfiguratorTemplate` that can define some of the following properties in the spec:

- templates
- volumeMounts
- renderTarget

The `templates` defined can use the go templating syntax to create the configuration templates that the operator will render. Apart from the usual constructs, the templates will have access to the following resources with the constructs below:

- Pods (.Pods)
- Services (.Services)
- Ingresses (.Ingresses)

An example `KonfiguratorTemplate` with fluentd config looks like the following:

```yaml
apiVersion: konfigurator.stakater.com/v1alpha1
kind: KonfiguratorTemplate
metadata:
    labels:
        apps: yourapp
        group: com.stakater.platform
        provider: stakater
        version: 1.0.0
    name: yourapp
spec:
  renderTarget: ConfigMap
  app:
      name: testapp
      kind: Deployment
      volumeMounts:
      - mountPath: /var/cfg
        container: test
  templates:
      fluentd.conf: |
    {{- $podsWithAnnotations := whereExist .Pods "ObjectMeta.Annotations.fluentdConfiguration" -}}
    # Create concat filters for supporting multiline
    {{- range $pod := $podsWithAnnotations -}}
        {{- $config := first (parseJson $pod.ObjectMeta.Annotations.fluentdConfiguration) }}
        {{- range $containerConfig := $config.containers }}
    <filter kubernetes.var.log.containers.{{ (index $pod.ObjectMeta.OwnerReferences 0).Name }}**_{{ $pod.ObjectMeta.Namespace }}_{{ $containerConfig.containerName }}**.log>
        @type concat
        key log
        multiline_start_regexp {{ $containerConfig.expressionFirstLine }}
        flush_interval 5s
        timeout_label @LOGS
    </filter>
        {{- end }}
    {{- end }}
```

Konfigurator will render the templates provided in the resource and create a new configmap with the rendered configs and mount them to the app containers. It will also update the config if any kubernetes resource i.e., pods, services or ingresses change.

## KonfiguratorTemplate properties

You can set the following properties in KonfiguratorTemplate to customize your generated resource

| Name                           | Description                                                                                                                                                           | Example                                    |
|--------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------|
| renderTarget                   | This tells the operator where the underlying rendered config will be stored                                                                                           | `ConfigMap` or `Secret`                    |
| app.name                       | This is the name of your app, it needs to be equal to the name specified in your Deployment, DaemonSet or StatefulSet                                                 | `fluentd`                                  |
| app.Kind                       | This specifies the resource on which your app is running on                                                                                                           | `Deployment`, `DaemonSet` or `StatefulSet` |
| app.volumeMounts               | This is an array which lists where the rendered resource will be mounted                                                                                              |                                            |
| app.volumeMounts.mountPath     | The path inside the container where you want the rendered resource to be mounted                                                                                      | `/home/app/config/`                        |
| app.volumeMounts.containerName | The container name inside which the resource will be mounted                                                                                                          | `my-container`                             |
| app.templates                  | A list of key value pairs. All the configuration templates go inside this property. You can paste your static config as is inside this block and it will work as well | `app.config: someConfig`                   |
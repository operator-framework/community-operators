# ![](assets/web/Konfigurator-round-100px.png) Konfigurator

## Problem

Dynamically generating app configuration when kubernetes resources change.

## Solution

A kubernetes operator that can dynamically generate app configuration when kubernetes resources change

## Features

- Render Configurations to
  - ConfigMap
  - Secret
- Support for GO Templating Engine
- Custom helper functions
- Support to watch the following Kubernetes Resources
  - Pods
  - Services
  - Ingresses

## Deploying to Kubernetes

Deploying Konfigurator requires:

1. Deploying CRD to your cluster
2. Deploying Konfigurator operator

You can deploy the CRD and operator on your kubernetes cluster via any of the following methods.

### Vanilla Manifests

You can apply vanilla manifests by running the following command

```bash
kubectl apply -f https://raw.githubusercontent.com/stakater/Konfigurator/master/deployments/kubernetes/konfigurator.yaml
```

Konfigurator by default looks for **KonfiguratorTemplate** only in the namespace where it is deployed, but it can be managed to work globally, you would have to change the `WATCH_NAMESPACE` environment variable to "" in the above manifest. e.g. change `WATCH_NAMESPACE` section to:

```yaml
            - name: WATCH_NAMESPACE
              value: ""
```

### Helm Charts

Alternatively if you have configured helm on your cluster, you can add konfigurator to helm from our public chart repository and deploy it via helm using below mentioned commands

```bash
helm repo add stakater https://stakater.github.io/stakater-charts

helm repo update

helm install stakater/konfigurator
```

Once Konfigurator is running, you can start creating resources supported by it. For details about its custom resources, look [here](https://github.com/stakater/Konfigurator/tree/master/docs/konfigurator-template.md).

To make Konfigurator work globally, you would have to change the `WATCH_NAMESPACE` environment variable to "" in values.yaml. e.g. change `WWATCH_NAMESPACE` section to:

```yaml
  env:
  - name: WATCH_NAMESPACE
    value: ""
```

## Help

**Got a question?**
File a GitHub [issue](https://github.com/stakater/Konfigurator/issues), or send us an [email](mailto:stakater@gmail.com).

### Talk to us on Slack

Join and talk to us on Slack for discussing Konfigurator

[![Join Slack](https://stakater.github.io/README/stakater-join-slack-btn.png)](https://stakater-slack.herokuapp.com/)
[![Chat](https://stakater.github.io/README/stakater-chat-btn.png)](https://stakater.slack.com/messages/CC8R7L8KG/)

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/stakater/Konfigurator/issues) to report any bugs or file feature requests.

### Developing

PRs are welcome. In general, we follow the "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull request** so that we can review your changes

NOTE: Be sure to merge the latest from "upstream" before making a pull request!

## Changelog

View our closed [Pull Requests](https://github.com/stakater/Konfigurator/pulls?q=is%3Apr+is%3Aclosed).

## License

Apache2 © [Stakater](http://stakater.com)

## About

`Konfigurator` is maintained by [Stakater][website]. Like it? Please let us know at <hello@stakater.com>

See [our other projects][community]
or contact us in case of professional services and queries on <hello@stakater.com>

  [website]: http://stakater.com/
  [community]: https://github.com/stakater/

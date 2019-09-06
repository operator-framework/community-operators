# Required fields within your CSV

## Preparing your CSV for use with OLM

Before you begin, we strongly advise that you follow Operator-Lifecycle-Manager's docs on [building a CSV for the Operator Framework](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/building-your-csv.md). These outline the functional purpose of the CSV and which fields are required for installing your Operator CSV through OLM.

## Required fields for OperatorHub

An Operator's CSV must contain the following fields and annotations for it to be displayed properly within OperatorHub.io and OperatorHub in OCP. Below is a guideline, explaining each field and at the bottom of this document is a full example of such a CSV.

```yaml
metadata:
  annotations:
    capabilities: One of the following: Basic Install, Seamless Upgrades, Full Lifecycle, Deep Insights, Auto Pilot. For more information see https://www.operatorhub.io/images/capability-level-diagram.svg
    categories: A comma separated list of categories from the values below. If not set, this will be set to "Other" in the UI
    containerImage: The repository that hosts the operator image. The format should match ${REGISTRYHOST}/${USERNAME}/${NAME}:${TAG}
    createdAt: The date that the operator was created. The format should match yyyy-mm-ddThh:mm:ssZ
    support: The name of the individual, company, or service that maintains this operator
    repository: (Optional) a URL to a source code repository of the Operator, intended for community Operators to direct users where to file issues / bug
    alm-examples: A string of a JSON list of example CRs for the operator's CRDs
    description: |-
      A short description of the operator that will be displayed on the marketplace tile
      If this annotation is not present, the `spec.description` value will be shown instead
      In either case, only the first 135 characters will appear
spec:
  displayName: A short, readable name for the operator
  description: A detailed description of the operator, preferably in markdown format
  icon: 
  - base64data: A base 64 representation of an image or logo associated with your operator
    mediatype: One of the following: image/png, image/jpeg, image/gif, image/svg+xml
  version: The operator version in semver format
  maintainers:
  - name: The name of the individual, company, or service that maintains this operator
    email: Email to reach maintainer
  provider:
    name: The name of the individual, company, or service that provides this operator
  links:
  - name: Title of the link (ex: Blog, Source Code etc.)
    url: url/link
  keywords:
  - 'A list of words that relate to your operator'
  - 'These are used when searching for operators in the UI'
```

### Logo requirements

The logo for your Operator is inlined into the CSV as a base64-encoded string. The height:width ratio should be 1:2. The maximum dimensions are 80px for width and 40px in height.

### Categories

For the best user experience, choose from the following categories:

| Category  |
|-----------|
| AI/Machine Learning |
| Application Runtime |
| Big Data |
| Cloud Provider |
| Database |
| Developer Tools |
| Integration & Delivery |
| Logging & Tracing |
| Monitoring |
| Networking |
| OpenShift Optional |
| Security |
| Storage |
| Streaming & Messaging |

If none of these categories fit your operator, please open a PR against this repo to edit this doc and we will work with you to propagate this change to [operator-courier](https://github.com/operator-framework/operator-courier) so that your operator can get through CI tests.

## Example CSV

Below is an example of what the descheduler CSV may look like if it contained the expected annotations:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
    capabilities: Seamless Upgrades
    categories: "OpenShift Optional"
    containerImage: registry.svc.ci.openshift.org/openshift/origin-v4.0:descheduler-operator
    createdAt: 2019-01-01T11:59:59Z
    description: An operator to run the OpenShift descheduler
    repository: https://github.com/openshift/descheduler-operator
    alm-examples: |
      [
        {
          "apiVersion": "descheduler.io/v1alpha1",
          "kind": "Descheduler",
          "metadata": {
            "name": "example-descheduler-1"
          },
          "spec": {
            "schedule": "*/1 * * * ?",
            "strategies": [
              {
                "name": "lownodeutilization",
                "params": [
                  {
                    "name": "cputhreshold",
                    "value": "10"
                  },
                  {
                    "name": "memorythreshold",
                    "value": "20"
                  },
                  {
                    "name": "memorytargetthreshold",
                    "value": "30"
                  }
                ]
              }
            ]
          }
        }
      ]
...
...
...
spec:
  displayName: Descheduler
  description: |-
    # Descheduler for Kubernetes

    ## Introduction

    Scheduling in Kubernetes is the process of binding pending pods to nodes, and is performed by
    a component of Kubernetes called kube-scheduler. The scheduler's decisions, whether or where a
    pod can or can not be scheduled, are guided by its configurable policy which comprises of set of
    rules, called predicates and priorities. The scheduler's decisions are influenced by its view of
    a Kubernetes cluster at that point of time when a new pod appears first time for scheduling.
    As Kubernetes clusters are very dynamic and their state change over time, there may be desired
    to move already running pods to some other nodes for various reasons

    * Some nodes are under or over utilized.
    * The original scheduling decision does not hold true any more, as taints or labels are added to
    or removed from nodes, pod/node affinity requirements are not satisfied any more.
    * Some nodes failed and their pods moved to other nodes.
      New nodes are added to clusters.

    Consequently, there might be several pods scheduled on less desired nodes in a cluster.
    Descheduler, based on its policy, finds pods that can be moved and evicts them. Please
    note, in current implementation, descheduler does not schedule replacement of evicted pods
    but relies on the default scheduler for that.

    ## Note

    Any api could be changed any time without any notice. That said, your feedback is
    very important and appreciated to make this project more stable and useful.
  icon:
  - base64data: this+is+a+base64-string==
    mediatype: image/png
  version: 0.0.1
  provider:
    name: Red Hat, Inc.
  maintainers:
  - email: support@redhat.com
    name: Red Hat
  links:
  - name: GitHub Repository
    url: https://github.com/openshift/descheduler-operator
  keywords: ['deschedule', 'scale', 'binpack', 'efficiency']
 ...
 ...
 ...
```

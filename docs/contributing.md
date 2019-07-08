# Submitting your Operator

:+1::tada: First off, thanks for taking the time to contribute your Operator! :tada::+1:

## A primer to Kubernetes Community Operators

This projects collects Operators and publishes them to OperatorHub.io, a central registry for community-powered Kubernetes Operators. For OperatorHub.io your Operator needs to work with vanilla Kubernetes.
This project also collects Community Operators that work with OpenShift to be displayed in the embedded OperatorHub. If you are new to Operators, start [here](https://github.com/operator-framework/getting-started).

## Package your Operator

This repository makes use of the [Operator Framework](https://github.com/operator-framework) and its packaging concept for Operators. Your contribution is welcome in the form of a _Pull Request_ with your Operator packaged for use with [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager/).

### Create a ClusterServiceVersion

To add your operator to any of the above platforms, you will need to submit your Operator packaged for use with [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager/). This mainly consists of a YAML file called `ClusterServiceVersion` which contains references to all of the `CustomResource Definitions` (CRDs), RBAC rules, `Deployment` and container image needed to install and securely run your Operator. It also contains user-visible info like a description of its features and supported Kubernetes versions (also see  further recommendations below).  Note that your Operator is not supposed to self-register it's CRDs.

[Follow this guide to create an OLM-compatible CSV for your operator](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/building-your-csv.md). You can also see an example [here](./required-fields.md#example-csv). An Operator's CSV must contain the fields and mentioned [here](./required-fields.md#required-fields-for-operatorhub) for it to be displayed properly within the various platforms.

### Bundle format

Your Operator package will be formatted as a `bundle` which is a directory named after your Operator with all `CustomResourceDefinitions`, the `ClusterServiceVersion` and the package definiton in separate YAML manifests.

Follow this example, assuming your Operator bundle is called `my-operator`. The bundle name should also correspond to the `name` field in the CSV.

```bash
$ ls my-operator/
my-operator.v1.0.0.clusterserviceversion.yaml
my-operator-crd1.crd.yaml
my-operator-crd2.crd.yaml
my-operator.package.yaml
```

Subsequent updates to your Operator should result in new CSV files, and potentially updated CRDs - they should all land in the directory mentioned above.

The `package.yaml` describes the bundle. It provides the bundle name, a selection of channels pointing to potentially different CSVs and a default channel. Use channels to allow your users to select a different update cadence, e.g. `stable` vs. `nightly`. If you have only a single channel the use of `defaultChannel` is optional.

An example of `my-operator.package.yaml`:

```yaml
packageName: my-operator
channels:
- name: stable
  currentCSV: my-operator.v1.0.2
- name: nightly
  currentCSV: my-operator.v1.1.3-beta
defaultChannel: stable
```

Your CSV versioning should follow [semantic versioning](https://semver.org/) concepts. Again, `packageName`, the suffix of the `package.yaml` file name and the field in `spec.name` in the CSV should all refer to the same Operator name.

### Updating your existing Operator

Similarly to add a new Operator, to update your Operator you need to submit a PR with any changes to your Operator resources. Please create a new CSV when you submit more than cosmetic fixes. Within your new CSV, reference your previous CSV like so: `replaces: my-operator.v1.0.0`

This indicates that existing installations of your Operator may be upgraded seamlessly to the new version. It is encouraged to use continuous delivery to update your Operator often as new features are added and bugs are fixed.

## Provide information about your Operator

A large part of the information gathered in the CSV is used for user-friendly visualization on [OperatorHub.io](https://operatorhub.io) or components like the embedded OperatorHub in OpenShift. Your work is on display, so please ensure to provide relevant information in your Operator's description, specifically covering:

* What the managed application is about and where to find more information
* The features your Operator and how to use it
* Any manual steps required to fulfill pre-requisites for running / installing your Operator

## Test locally before you contribute

The team behind OperatorHub.io will support you in making sure you are Operator works and is packaged correctly. You can accelerate your submission greatly by testing your Operator with the Operator Framework by following our [documentation for local testing](./testing-operators.md). You are responsible for testing your Operator's APIs when deployed with OLM.

## Verify CI test results

Every PR against this repository is tested via [Continuous Integration](./ci.md). During these tests your Operator will be deployed on either a `minikube` or OpenShift 4 environments and checked for a healthy deployment. Also several tools are run to check your bundle for completeness. These are the same tools as referenced in our [testing docs](./testing-operators.md). Pay attention to the result of GitHub checks.

## Where to contribute

There are 2 directories where you can contribute, depending on some basic requirements and where you would like your Operator to show up:

| Target Directory               | Appears on                 | Target Platform             | Requirements                             |
|--------------------------------|----------------------------|-----------------------------|------------------------------------------|
| `community-operators`          | Embedded OperatorHub in OpenShift 4 | OpenShift / OKD             | needs to work on OpenShift 4 or newer    |
| `upstream-community-operators` | OperatorHub.io             | Upstream Kubernetes | needs to work on Kubernetes 1.7 or newer |

These repositories are used by OpenShift 4 and OperatorHub.io respectively. Specifically, Operators for Upstream Kubernetes for OperatorHub.io won't automatically appear on the embedded OperatorHub in OpenShift and should not be used on OpenShift.

**If you Operator works on both Kubernetes and OpenShift, place a copy of your packaged bundle in the `upstream-community-operators` directory, as well as the `community-operators` directory. Submit them as separate PRs.**

For partners and ISVs, certified operators can now be submitted via connect.redhat.com. If you have submitted your Operator there already, please ensure your submission here uses a different package name (refer to the README for more details).

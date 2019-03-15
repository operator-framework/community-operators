# About this repository

This repo is the canonical source for Kubernetes Operators that appear on [OperatorHub.io](https://operatorhub.io), [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io).

# Know what to contribute

To add your operator to any of the above platforms, you will need to submit a PR with your Operator packaged for use with [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager/). This package contains all of the Custom Resource Definitions (CRDs), access control rules and references to the container image needed to install and securely run your Operator, plus other info like a description of its features and supported Kubernetes versions. [Follow this guide to create an OLM-compatible CSV for your operator](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/building-your-csv.md), CRDs, and the package.yaml file for your operator.

An Operator's CSV must contain the annotations mentioned [here][required-fields] for it to be displayed properly within the various platforms.

Your PR needs to be formatted as a `bundle` which is a directory named after your Operator with all `CustomResourceDefinitions`, the `ClusterServiceVersion` and package definitons in separate YAML manifests like so:

```bash
$ ls my-operator/
my-operator.v1.0.0.clusterserviceversion.yaml
my-operator-crd1.crd.yaml
my-operator-crd2.crd.yaml
my-operator.package.yaml
```
Please note that the directory name should match the `packageName` of your operator in it's `package.yaml`, and should be used as a prefix for all files in the bundle. Please follow the conventions of the example above.

# Where to contribute

There are 4 directories where you can contribute, depending on a set of requirements:

| Target Directory               | Type of Operators              | Target Platform             | Requirements                                                  |
|--------------------------------|--------------------------------|-----------------------------|---------------------------------------------------------------|
| `community-operators`          | Community OpenShift Operators  | OpenShift / OKD             | needs to work on OpenShift 3.11 or newer                      |
| `upstream-community-operators` | Community Kubernetes Operators | Kubernetes / OperatorHub.io | needs to work on Kubernetes 1.7 or newer                      |
| `redhat-operators`             | Red Hat-provided Operators     | OpenShift / OKD             | needs to work on OpenShift 3.11 or newer                      |
| `certified-operators`          | Certified 3rd party Operators  | OpenShift                   | needs to be commercially supported and certified with Red Hat |

The column _Target Platform_ denotes both, where this Operator will be visible (embedded OperatorHub in OpenShift / OKD or OperatorHub.io) and where they are intended to run.<br/>
**If you Operator fulfills multiple criteria place a copy of your bundle in the appropriate folders respectively.**

# Before submitting a PR

The maintainers will work with you to make sure your Operator has the required metadata to function properly and be displayed with useful information for the end user.

You can help us with that by validating your `bundle` with [operator-courier](https://github.com/operator-framework/operator-courier). This tool will check against the [required fields][required-fields] in your CSV.

```sh
operator-courier verify --ui_validate_io path/to/bundle
```

## Updating your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Within your CSV, add the additional `replaces: my-operator.v1.0.0` parameter which indicates that existing installations of your Operator may be upgraded seamlessly to the new version. It is encouraged to use continuous delivery to update your Operator often as new features are added and bugs are fixed.

[Read more about testing your Operator](docs/testing-operators.md)

## Future Automation

New Operators are reviewed manually by the maintainers to ensure that contain all [required information][required-fields]. In the near future, automation will be added to check for required values and run a suite of automated tests against a live cluster.

## Reporting Bugs

Report bugs using the project issue tracker.

[required-fields]: https://github.com/operator-framework/community-operators/blob/master/docs/required-fields.md

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

There are 3 directories where you can contribute, depending on a set of requirements:

| Target Directory               | Type of Operators              | Target Platform             | Requirements                                                  |
|--------------------------------|--------------------------------|-----------------------------|---------------------------------------------------------------|
| `community-operators`          | Community OpenShift Operators  | OpenShift / OKD             | needs to work on OpenShift 3.11 or newer                      |
| `upstream-community-operators` | Community Kubernetes Operators | Kubernetes / OperatorHub.io | needs to work on Kubernetes 1.7 or newer                      |
| `redhat-operators`             | Red Hat-provided Operators     | OpenShift / OKD             | needs to work on OpenShift 3.11 or newer                      |

The column _Target Platform_ denotes where this Operator will be visible (embedded OperatorHub in OpenShift and OKD, or OperatorHub.io for Kubernetes) and where it's intended to run.

**If you Operator works on both Kubernetes and OpenShift, place a copy of your bundle in the `upstream-community-operators` directory, as well as the appropriate OpenShift directory.**

For partners and ISVs, certified operators can now be submitted via connect.redhat.com

Note that OpenShift and OKD clusters by default come with access to operators from `community-operators`, `redhat-operators`, and certified operators. Please keep this in mind when submitting operators, as duplicate operators across these sources will not be tolerated. 

# Before submitting a PR

## Test your Operator

Upon creating a pull request against this repo, a set of CI pipelines will run, see more details [here](https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md).

You can help speed up the review of your PR by [testing manually](https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md#manual-testing-on-kubernetes).

## Verify your Operator Metadata

The maintainers will work with you to make sure your Operator has the required metadata to function properly and be displayed with useful information for the end user.

You can help us with that by validating your `bundle` with [operator-courier](https://github.com/operator-framework/operator-courier). This tool will check against the [required fields][required-fields] in your CSV.

```sh
operator-courier verify --ui_validate_io path/to/bundle
```

## Preview your Operator on OperatorHub.io

If you are submitting your Operator in the `upstream-community-operators` directory your Operator will appear on OperatorHub.io. You can preview how your Operator would be rendered there by using this tool: [https://operatorhub.io/preview](https://operatorhub.io/preview)

## Updating your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Within your CSV, add the additional `replaces: my-operator.v1.0.0` parameter which indicates that existing installations of your Operator may be upgraded seamlessly to the new version. It is encouraged to use continuous delivery to update your Operator often as new features are added and bugs are fixed.

[Read more about testing your Operator](docs/testing-operators.md)

## Operator CI Pipeline

New Operator PRs are automatically checked for [required fields][required-fields] using the [`operator-courier`][operator-courier] and are run through a [`operator-sdk scorecard`][sdk-scorecard] test against a live cluster. PRs are also reviewed manually by the maintainers to ensure that the automated tests are running smoothly and that Operators with additional setup can be verified.

[You can learn more about the tests run on submitted Operators in this doc](docs/testing-operators.md)

## Reporting Bugs

Report bugs using the project issue tracker.

[required-fields]: https://github.com/operator-framework/community-operators/blob/master/docs/required-fields.md
[operator-courier]: https://github.com/operator-framework/operator-courier
[sdk-scorecard]:https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md

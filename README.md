# OperatorHub.io Community Operators

This repo is the canonical source for Operators that appear in [OperatorHub.io](https://operatorhub.io).

## Adding your Operator

To add your operator to this repo, you will need to submit a PR with your Operator resources in a new directory named after your Operator within the `community-operators/` directory:

```bash
$ ls community-operators/my-operator/
my-operator.v1.0.0.clusterserviceversion.yaml
my-operator-crd1.crd.yaml
my-operator-crd2.crd.yaml
my-operator.package.yaml
```

Each OperatorHub entry contains all of the Custom Resource Definitions (CRDs), access control rules and references to the container image needed to install and securely run your Operator, plus other info like a description of its features and supported Kubernetes versions. [Follow this guide to create an OLM-compatible CSV for your operator](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/building-your-csv.md), CRDs, and the package.yaml file for your operator.

An Operator's CSV must contain the annotations mentioned [here][required-fields] for it to be displayed properly within the OperatorHub.io UI.

## Updating your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Within your CSV, add the additional `replaces: my-operator.v1.0.0` parameter which indicates that existing installations of your Operator may be upgraded seamlessly to the new version. It is encouraged to use continuous delivery to update your Operator often as new features are added and bugs are fixed.

[Read more about testing your Operator](docs/testing-operators.md)

## Future Automation

New Operators are reviewed manually by the maintainers to ensure that contain all [required information][required-fields]. In the near future, automation will be added to check for required values and run a suite of automated tests against a live cluster.

## Reporting Bugs

Report bugs using the project issue tracker.

[required-fields]: https://github.com/operator-framework/community-operators/blob/master/docs/required-fields.md

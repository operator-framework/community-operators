# About this repository

This repo is the canonical source for Kubernetes Operators that appear on [OperatorHub.io](https://operatorhub.io), [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io).

## Add your Operator

We would love to see your Operator being added to this collection. We currently use automated vetting via continuous integration plus manual review to curate a list of high-quality, well-documented Operators. If you are new to Kubernetes Operators start [here](https://github.com/operator-framework/getting-started).

If you have an existing Operator read our [contribution guidelines](./docs/contributing.md) on how to package and test it. Then submit a Pull Request.

## Submitting your PR

Review this [checklist](./docs/pull_request_template.md) upon creating a PR and after you acknowledged the contribution guidelines.

## Update your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Refere to our [contribution guide](docs/contributing.md#updating-your-existing-operator) for more details.

## Test your Operator

Upon creating a pull request against this repo, a set of CI pipelines will run, see more details [here](./docs/ci.md).

You can help speed up the review of your PR by [testing locally](./docs/testing-operators.md).

## Preview your Operator on OperatorHub.io

If you are submitting your Operator in the `upstream-community-operators` directory your Operator will appear on OperatorHub.io. You can preview how your Operator would be rendered there by using the [preview tool](https://operatorhub.io/preview).

## Reporting Bugs

Use the issue tracker in this repository to report bugs.
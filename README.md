[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![Upstream Operator Catalog Status](https://quay.io/repository/operator-framework/upstream-community-operators/status "Upstream Operator Catalog Status")](https://quay.io/repository/operator-framework/upstream-community-operators)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- **Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)* -->

- [About this repository](#about-this-repository)
- [Add your Operator](#add-your-operator)
- [Test your Operator before submitting a PR](#test-your-operator-before-submitting-a-pr)
- [Preview your Operator on OperatorHub.io](#preview-your-operator-on-operatorhubio)
- [Submitting your PR](#submitting-your-pr)
- [Update your Operator](#update-your-operator)
- [CI Tests your Operator](#ci-tests-your-operator)
- [Reporting Bugs](#reporting-bugs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## About this repository

This repo is the canonical source for Kubernetes Operators that appear on [OperatorHub.io](https://operatorhub.io), [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io).

## Add your Operator

We would love to see your Operator being added to this collection. We currently use automated vetting via continuous integration plus manual review to curate a list of high-quality, well-documented Operators. If you are new to Kubernetes Operators start [here](https://github.com/operator-framework/getting-started).

If you have an existing Operator read our [contribution guidelines](./docs/contributing.md) on how to package and test it. Then test your Operator locally and submit a Pull Request.

## Test your Operator before submitting a PR

You can leverage the `Makefile` at the top-level directory of this repository to test your Operator prior to submitting it. Assuming you followed the contribution guide, you can run the entire suite on a Linux or macOS system with `Docker` and [`KIND`](https://github.com/kubernetes-sigs/kind) installed:

`make operator.test OP_PATH=upstream-community-operators/my-operator`

Tests not passing? Check [here](docs/using-scripts.md#troubleshooting).

## Preview your Operator on OperatorHub.io

If you are submitting your Operator in the `upstream-community-operators` directory your Operator will appear on OperatorHub.io. You can preview how your Operator would be rendered there by using the [preview tool](https://operatorhub.io/preview).

## Submitting your PR

Review this [checklist](./docs/pull_request_template.md) upon creating a PR and after you acknowledged the contribution guidelines.

## Update your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Refere to our [contribution guide](docs/contributing.md#updating-your-existing-operator) for more details.

## CI Tests your Operator

Upon creating a pull request against this repo, a set of CI pipelines will run, see more details [here](./docs/ci.md). The pipeline will actually run the same `Makefile` commands you use to test locally.

You can help speed up the review of your PR by testing locally, either [manually](./docs/testing-operators.md) or [using scripts](./docs/using-scripts.md)

Tests not passing? Check [here](docs/using-scripts.md#troubleshooting).

## Reporting Bugs

Use the issue tracker in this repository to report bugs.


---
title: Community operators
summary: Documentation for communityoperators
authors:
    - Daniel Messer
    - Jozef Breza
    - Martin Vala
date: 2020-11-18
some_url: https://github.com/operator-framework/community-operators
---

[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![Upstream Operator Catalog Status](https://quay.io/repository/operator-framework/upstream-community-operators/status "Upstream Operator Catalog Status")](https://quay.io/repository/operator-framework/upstream-community-operators)

## About this repository

This repo is the canonical source for Kubernetes Operators that appear on [OperatorHub.io](https://operatorhub.io), [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io).

## Documentation
Full documentation is located at [here](https://operator-framework.github.io/community-operators/)

## Add your Operator

We would love to see your Operator being added to this collection. We currently use automated vetting via continuous integration plus manual review to curate a list of high-quality, well-documented Operators. If you are new to Kubernetes Operators start [here](https://sdk.operatorframework.io/build/).

If you have an existing Operator read our [contribution guidelines](./contributing.md) on how to package and test it. Then test your Operator locally and submit a Pull Request.

## Test your Operator before submitting a PR

You can use our [test suite](./using-current-test-suite.md) to test your Operator prior to submitting it. Our [test suite](./using-current-test-suite.md) will help you to install it. Then assuming you followed the contribution guide, you can run the entire suite on a Linux or macOS system with `Docker` and [`KIND`](https://github.com/kubernetes-sigs/kind) installed:

`bash <(curl -sL https://cutt.ly/operator-test) all upstream-community-operators/<operoator>/<version>`

Tests not passing? Check [test suite](./using-current-test-suite.md) for more info.

## Preview your Operator on OperatorHub.io

If you are submitting your Operator in the `upstream-community-operators` directory your Operator will appear on OperatorHub.io. You can preview how your Operator would be rendered there by using the [preview tool](https://operatorhub.io/preview).

## Submitting your PR

Review this [checklist](./pull_request_template.md) upon creating a PR and after you acknowledged the contribution guidelines.
Do not forget to add [ci.yaml](./operator-versioning.md) to the top level of your operator. Otherwise only `semver` mode will be supported.

## Update your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Refere to our [contribution guide](./contributing.md#updating-your-existing-operator) for more details.

## CI Tests your Operator

Upon creating a pull request against this repo, a set of CI pipelines will run, see more details [here](/ci.md). The pipeline will actually run the same commands you use to test locally.

You can help speed up the review of your PR by testing locally, either [manually](./testing-operators.md) or [using scripts](./using-current-test-suite.md). For troubleshooting failing tests consult the [manual test steps](./testing-operators.md).

## Reporting Bugs

Use the issue tracker in this repository to report bugs.

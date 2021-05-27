---
title: Community operators
summary: Documentation for communityoperators
authors:
    - Daniel Messer
    - Jozef Breza
    - Martin Vala
date: 2020-11-18
# some_url: https://github.com/operator-framework/community-operators
---

[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![Upstream Operator Catalog Status](https://quay.io/repository/operator-framework/upstream-community-operators/status "Upstream Operator Catalog Status")](https://quay.io/repository/operator-framework/upstream-community-operators)

## About this repository

This repo is the canonical source for Kubernetes Operators that appear on [OperatorHub.io](https://operatorhub.io), [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io).

<!-- ## Documentation
Full documentation is generated via [mkdoc](https://www.mkdocs.org/) and located at [https://operator-framework.github.io/community-operators/](https://operator-framework.github.io/community-operators/) -->

## Add your Operator

We would love to see your Operator being added to this collection. We currently use automated vetting via continuous integration plus manual review to curate a list of high-quality, well-documented Operators. If you are new to Kubernetes Operators start [here](https://sdk.operatorframework.io/build/).

If you have an existing Operator read our [contribution guidelines](./packaging-operator.md) on how to [package](./packaging-operator.md) and [test](./testing-operators.md) it. Then test your Operator locally and submit a Pull Request.

## Test your Operator before submitting a PR

**IMPORTANT** Kubernetes has been deprecating API(s), which will be removed and no longer available in `1.22` and in the Openshift version `4.9`. Note that your project will be unable to use them on `OCP 4.9/K8s 1.22`. Then, it is strongly recommended to check [Deprecated API Migration Guide from v1.22](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#v1-22) and ensure that your projects have them migrated and are not using any deprecated API. If you are looking to distribute your solution on OKD/Openshift catalogs see [OKD/OpenShift Catalogs criteria and options](./packaging-required-criteria-ocp.md).

You can use our [test suite](./operator-test-suite.md) to test your Operator prior to submitting it. Our [test suite](./operator-test-suite.md) will help you to install it. Then assuming you followed the contribution guide, you can run the entire suite on a Linux or macOS system with `Docker` installed:

```bash
cd <community-operators-project>
bash <(curl -sL https://cutt.ly/WhkV76k) \
  kiwi,lemon,orange \
  <operator-stream>/<operator-name>/<operator-version>
```
Tests are not passing or you want to know more? Check [test suite](./operator-test-suite.md) for more info.

### Validating the bundle with SDK

Note that you can validate the bundle via [`operator-sdk bundle validate`][sdk-cli-bundle-validate] against the entire suite of validators for Operator Framework, in addition to required bundle validators:

```sh
operator-sdk bundle validate ./bundle --select-optional suite=operatorframework
```

**Note** If you used [operator-sdk](https://github.com/operator-framework/operator-sdk) to build your project and to build your bundle with the target `make bundle` then you can leverage in [`operator-sdk scorecard`][sdk-cli-scorecard-bundle] to perform functional tests as well.

## Preview your Operator on OperatorHub.io

You can preview how your Operator would be rendered there by using the [preview tool](https://operatorhub.io/preview). If you are submitting your Operator in the `upstream-community-operators` directory your Operator will appear on OperatorHub.io.

## Submitting your PR

Review this [checklist](./pull_request_template.md) upon creating a PR and after you acknowledged the contribution guidelines.
Do not forget to add [ci.yaml](./operator-ci-yaml.md#operator-versioning) to the top level of your operator. Otherwise only `semver` mode will be supported.

## Update your Operator

Similarly, to update your operator you need to submit a PR with any changes to your Operator resources. Refer to our [contribution guide](./operator-ci-yaml.md#operator-versioning) for more details.

## CI Tests your Operator

Upon creating a pull request against this repo, a set of CI pipelines will run, see more details [here](/tests-in-pr.md). The pipeline will actually run the same commands you use to test locally.

You can help speed up the review of your PR by testing locally, either [manually](./testing-operators.md) or [using scripts](./operator-test-suite.md). For troubleshooting failing tests consult the [manual test steps](./testing-operators.md) or see specific error messages solved in [troubleshooting guide](https://github.com/operator-framework/community-operators/blob/master/docs/troubleshooting.md).

## Reporting Bugs

Use the issue tracker in this repository to report bugs.

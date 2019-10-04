[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- **Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)* -->

- [About this repository](#about-this-repository)
- [Add your Operator](#add-your-operator)
- [Submitting your PR](#submitting-your-pr)
- [Update your Operator](#update-your-operator)
- [Test your Operator](#test-your-operator)
- [Preview your Operator on OperatorHub.io](#preview-your-operator-on-operatorhubio)
- [Reporting Bugs](#reporting-bugs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## About this repository

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

You can help speed up the review of your PR by testing locally, either [manually](./docs/testing-operators.md) or [using scripts](./docs/using-scripts.md)

## Preview your Operator on OperatorHub.io

If you are submitting your Operator in the `upstream-community-operators` directory your Operator will appear on OperatorHub.io. You can preview how your Operator would be rendered there by using the [preview tool](https://operatorhub.io/preview).

## Reporting Bugs

Use the issue tracker in this repository to report bugs.

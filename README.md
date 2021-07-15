# Community Operators
[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![Upstream Operator Catalog Status](https://quay.io/repository/operator-framework/upstream-community-operators/status "Upstream Operator Catalog Status")](https://quay.io/repository/operator-framework/upstream-community-operators)

## [New] Repository was split
> Dear OperatorHub.io and OpenShift Operator Community,
>
> As of July 15, 2021 we would like to announce that community-operators are migrated to 2 different repositories. We are doing this for better separation of concerns.
>
> The directory `upstream-community-operators` keeping Kubernetes operators is `https://github.com/k8s-operatorhub/community-operators` and `community-operators` directory keeping Openshift operators is `https://github.com/redhat-openshift-ecosystem/community-operators-prod`.
>
> Also there are no more `upstream-community-operators` nor `community-operators directories`, just simply `operators` according to the repository.

|Old directory|New directory|New repo|
|-------------|-------------|--------
|upstream-community-operators|operators|https://github.com/k8s-operatorhub/community-operators|
|community-operators|operators|https://github.com/redhat-openshift-ecosystem/community-operators-prod|

## About this repository

This repo is the canonical source for Kubernetes Operators that appear on [OperatorHub.io](https://operatorhub.io), [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io).

## Documentation

Full documentation is generated via [mkdoc](https://www.mkdocs.org/) and is located at [https://operator-framework.github.io/community-operators/](https://operator-framework.github.io/community-operators/)

## IMPORTANT NOTICE

**IMPORTANT** Kubernetes has been deprecating API(s) which will be removed and no longer available in `1.22` and in the Openshift version `4.9`. Note that your project will be unable to use them on `OCP 4.9/K8s 1.22` and then, it is strongly recommended to check [Deprecated API Migration Guide from v1.22][k8s-deprecated-guide] and ensure that your projects have them migrated and are not using any deprecated API.

### FOR OPENSHIFT COMMUNITY OPERATORS

However, If you still need to publish the operator bundles with any of these API(s) on [OpenShift Container Platform](https://openshift.com) and [OKD](https://okd.io) ensure that it is configured with the criteria defined in [OKD/OpenShift Catalogs criteria and options](./docs/packaging-required-criteria-ocp.md).

## Reporting Bugs

Use the issue tracker in this repository to report bugs.

[k8s-deprecated-guide]: https://kubernetes.io/docs/reference/using-api/deprecation-guide/#v1-22
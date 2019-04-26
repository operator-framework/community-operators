# Testing Operators

This document describes how operators submitted to `community-operators` are expected to be tested. Operators should be tested by their authors before submission, and will undergo [Operator Lifecycle Manager][olm] (OLM) deployment, [scorecard][sdk-scorecard], and [`operator-courier`][courier] testing in our CI environments on submission.

## PR Continuous Integration

Operators submitted to this repo are automatically tested on a Kubernetes cluster before being merged. The Kubernetes distribution used for testing depends on which directory the operator is submitted to. Ideally all tests should pass before merging.

### Tests

Operators are tested using several scripts found in the [`scripts/ci/`][scripts-ci] directory. When a PR is updated or modified, the CI configuration calls `scripts/ci/test-pr`, which calls `scripts/ci/test-operator` and `scripts/ci/verify-operator` for each operator updated in a PR that meets directory requirements for that CI environment. `test-operator` has two main functions: deploy an operator on the cluster using the [OLM][olm], and test the operator using the [scorecard][sdk-scorecard]. `verify-operator` runs [`operator-courier verify`][courier-verify] on an operators' [bundle][registry-bundle].

**Note**: CI test results do not explicitly prevent your operator from being merged _yet_. Test results will be used by PR reviewers to suggest changes before submission.

#### OLM

Deployment with the OLM involves creating several required manifest files to create `CustomResourceDefinitions` (CRD's) and the operators' `Deployment` using its `ClusterServiceVersion` (CSV) in-cluster. `test-operator` will create a [`operator-registry`][registry] Docker image containing the operators' bundled manifests, and `CatalogSource` and `Subscription` manifests that allow the OLM to find the registry image and deploy a particular CSV from the registry, respectively.

Failure to successfully deploy an operator using the OLM results in test failure, as all operators are expected to be deployable in this manner.

#### Scorecard

The [Operator SDK scorecard][sdk-scorecard] suggests modifications applicable to an operator based on development best-practices. The scorecard runs static checks on operator manifests and runtime tests to ensure an operator is using cluster resources correctly. A Custom Resource (CR) is created by the scorecard for use in runtime tests, so [`alm-examples`][olm-alm-examples] must be populated.

The scorecard assigns points to each passing component of the scorecard. The total number of points is a function of several factors, ex. number of CRD's, but a weighted total percentage is calculated for the overall test run. It is possible to get a score of 100%, but operators are not expected to achieve this.

`test-operator` injects a scorecard proxy container and volume into an operators' CSV manifest before deployment; this is necessary to get API server logs, from which the scorecard determines runtime test results. These modifications are not persistent, as they're only needed for testing.

**Note**: no explicit number of points or percentage is necessary to achieve before merging _yet_. These are suggestions to improve your operator.

#### operator-courier

The [`operator-courier verify`][courier] command verifies that a set of files is valid and can be bundled and pushed to [quay.io][quay]. Read the [docs][courier-docs] for more information.

### Upstream operators

Operators submitted to the `upstream-community-operators/` directory are tested against a [`minikube`][minikube] instance deployed on a [Travis CI][travis-ci] environment. The OLM is installed locally in this case.

### OpenShift operators

Operators submitted to the `community-operators/` directory are tested against an OpenShift 4.0 cluster deployed on AWS using the [`ci-operator`][ci-operator].

## Manual testing on Kubernetes

This section is for operator authors who want their operators to be available on OperatorHub.io which implies the target platform for this Operator is plain Kubernetes. Follow the below steps to test your Operator using OLM:

### Pre-Requisite

OLM is the component that will lifecycle your Operator. It also provides a packaging concept for storing Operators in a catalog that you can make available on cluster. Operators are installed from catalogs.
Follow these steps to deploy OLM: https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md.

**Tip**: you can get a local minikube-based OLM installation easily by running `make run-local` in your local copy of the [OLM repository][olm-repository].

### Package your Operator in an OLM catalog

Assuming you have Operator manifests (CSVs, CRDs, package.yaml) on-disk, you can follow these instructions to put them into a catalog: https://github.com/operator-framework/operator-registry#manifest-format

The result is a docker container which you can push to registry of your choice. This is a catalog containing your Operator manifests.

### Install your Operator using OLM and your catalog

With the catalog created, you can follow these instructions to add your catalog to OLM: https://github.com/operator-framework/operator-registry#using-the-catalog-with-operator-lifecycle-manager

In the last step you will create a `Subscription` that references your Operator from the catalog. Note that currently, in the same namespace where you create this, you also need to have an [`OperatorGroup`][operatorgroup] object defined. Its `spec.targetNamespaces` should at least contain the current namespace - or none at all to denote your Operator works cluster-wide.

Once the `Subscription` is created with an `OperatorGroup` present, OLM will install your Operator. The result is `ClusterServiceVersion` object in the namespace representing your installed Operator. It should be in state `Succeeded`. Your Operator is now deployed and ready to be tested.

## Manual testing on OpenShift

This section is for operator authors who want their operators to be available on OpenShift 4.0 clusters through OperatorHub and want to manually test that end to end workflow. The OLM comes pre-installed in OpenShift 4.0 clusters.

### Pre-Requisite

You need to have an account with `quay.io`. If you don't have one you can sign up for it at [quay.io][quay].

### Create your Quay app-registry repository

OperatorHub uses Quay's application repositories for storing the operator bundle. Follow [these instructions][quay-create-repo] to create your own application repository. Please note that the name of the repository should match the `packageName` field in the operator's package. Example: for the following package, the Quay repository name will be `myoperator`:
```
packageName: myoperator
channels:
- name: preview
  currentCSV: myoperator.0.1.1
```

### Pushing your operator bundle to Quay

Collect all CSV, CRD, and Package yamls into a directory. You can then use the [operator-courier][operator-courier] tool to verify and push your operator bundle to the Quay application repository you created.

Please note that we only support CRDs, CSVs and Packages to be present in your bundle.

### Linking the Quay application repository to your OpenShift 4.0 cluster

For OpenShift to become aware of the Quay application repository, an [`OperatorSource` CR][operatorsource-cr] need to be added to the cluster. An example `OperatorSource` is provided [here][operatorsource-cr-example]. If your Quay repository is private, please follow [these][marketplace-private-repo] instructions.

### Testing your operator

Once the `OperatorSource` CR has been added to the cluster, the new operator will show up on the OperatorHub UI. You can then either install it from the UI or follow the command line [instructions][marketplace-install].

[olm]:https://github.com/operator-framework/operator-lifecycle-manager/
[sdk-scorecard]:https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md
[courier]:https://github.com/operator-framework/operator-courier/
[minikube]:https://kubernetes.io/docs/setup/minikube/
[travis-ci]:https://travis-ci.org/
[ci-operator]: https://github.com/openshift/release/tree/master/ci-operator
[scripts-ci]:../scripts/ci/
[registry-bundle]:https://github.com/operator-framework/operator-registry#manifest-format
[courier-verify]:https://github.com/operator-framework/operator-courier/#command-line-interface
[registry]:https://github.com/operator-framework/operator-registry
[olm-alm-examples]:https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/building-your-csv.md#crd-templates
[courier-docs]:https://github.com/operator-framework/operator-courier/#operator-courier
[quay]:https://quay.io
[quay-create-repo]:https://docs.quay.io/guides/create-repo.html
[operator-courier]:https://github.com/operator-framework/operator-courier/#usage
[operatorsource-cr]:https://github.com/operator-framework/operator-marketplace#description
[operatorsource-cr-example]:https://github.com/operator-framework/operator-marketplace/blob/master/deploy/examples/community.operatorsource.cr.yaml
[marketplace-private-repo]:https://github.com/operator-framework/operator-marketplace/blob/master/docs/how-to-authenticate-private-repositories.md
[marketplace-install]:https://github.com/operator-framework/operator-marketplace#installing-an-operator-using-marketplace
[olm-repository]:https://github.com/operator-framework/operator-registry#using-the-catalog-with-operator-lifecycle-manager
[operatorgroup]:https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/operatorgroups.md#target-namespace-selection

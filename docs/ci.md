## PR Continuous Integration

Operators submitted to this repo are automatically tested on a Kubernetes cluster before being merged. The Kubernetes distribution used for testing depends on which directory the operator is submitted to. Ideally all tests should pass before merging.

### CI test scripts

Operators are tested using several scripts found in the [`scripts/ci/`][scripts-ci] directory. When a PR is updated or modified, the CI configuration calls a `Makefile` which provides multiple targets to test deployment and execution of your Operator. For each operator updated in a PR the following targets are executed:

- `operator.verify` - lints the Operator metadata (CSV, `package.yaml` and CRDs)

- `operator.install` - packages the Operator as part of the community catalog and tries to deploy it using OLM

- `operator.test` - executes `operator.install` and then runs [scorecard][sdk-scorecard] against the deployed Operator.

You can also run this pipeline locally by running the `Makefile` on your local machine. Follow our [documentation][test-script-docs] for more details.

#### OLM

Deployment with the OLM involves creating several required manifest files to create `CustomResourceDefinitions` (CRD's) and the operators' `Deployment` using its `ClusterServiceVersion` (CSV) in-cluster. `test-operator` will create a [`operator-registry`][registry] Docker image containing the operators' bundled manifests, and `CatalogSource` and `Subscription` manifests that allow the OLM to find the registry image and deploy a particular CSV from the registry, respectively.

Failure to successfully deploy an operator using the OLM results in test failure, as all operators are expected to be deployable in this manner.

#### Scorecard

The [Operator SDK scorecard][sdk-scorecard] suggests modifications applicable to an operator based on development best-practices. The scorecard runs static checks on operator manifests and runtime tests to ensure an operator is using cluster resources correctly. A Custom Resource (CR) is created by the scorecard for use in runtime tests, so [`alm-examples`][olm-alm-examples] must be populated.

The scorecard utility runs through multiple test scenarios, some of which are required and others are optional. Currently the tests are configured like this.

**Mandatory tests that need to pass for the PR to be accepted:**

- `checkspectest` - verifies that the CRs have a `spec` section

- `writingintocrshaseffecttest` - verifies that writing into the CR causes the Operator to issue requests against the Kubernetes API server

**Recommended tests that should pass in order to have a well-behaved operator:**

- `checkstatustest` - verifies whether the CRs `status` block gets updated by the Operator to indicate reconciliation.

See the [scorecard test documentation][scorecard-test-docs] for more information.

`test-operator` injects a scorecard proxy container and volume into an operators' CSV manifest before deployment; this is necessary to get API server logs, from which the scorecard determines runtime test results. These modifications are not persistent, as they're only needed for testing.

**Note**: no explicit number of points or percentage is necessary to achieve before merging _yet_. These are suggestions to improve your operator.

#### operator-courier

The [`operator-courier verify`][courier] command verifies that a set of files is valid and can be bundled and pushed to [quay.io][quay]. Read the [docs][courier-docs] for more information.

### Upstream operators

Operators submitted to the `upstream-community-operators/` directory are tested against a [`KIND`][kind] instance deployed on a [Travis CI][travis-ci] environment. The OLM is installed locally in this case.

### OpenShift operators

Operators submitted to the `community-operators/` directory are tested against an OpenShift 4.0 cluster deployed on AWS using the [`ci-operator`][ci-operator].

[olm]:https://github.com/operator-framework/otest-script-docsperator-lifecycle-manager/
[sdk-scorecard]:https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md
[scorecard-test-docs]:https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md#basic-operator
[courier]:https://github.com/operator-framework/operator-courier/
[kind]:https://github.com/kubernetes-sigs/kind
[travis-ci]:https://travis-ci.org/
[ci-operator]: https://github.com/openshift/release/tree/master/ci-operator
[scripts-ci]:../scripts/ci/
[registry-bundle]:https://github.com/operator-framework/operator-registry#manifest-format
[courier-verify]:https://github.com/operator-framework/operator-courier/#command-line-interface
[registry]:https://github.com/operator-framework/operator-registry/tree/release-4.3
[olm-alm-examples]:https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/building-your-csv.md#crd-templates
[courier-docs]:https://github.com/operator-framework/operator-courier/#operator-courier
[quay]:https://quay.io
[quay-create-repo]:https://docs.quay.io/guides/create-repo.html
[operator-courier]:https://github.com/operator-framework/operator-courier/#usage
[test-script-docs]:./using-scripts.md

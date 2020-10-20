# Automate testing your Operator locally

For convenience, in addition to the [manual test instructions](./testing-operators.md) we provide a `Makefile` based test automation. This will automate all the manual steps referred to in [Testing Operator Deployment on Kubernetes](./testing-operators.md#testing-operator-deployment-on-kubernetes). In addition the [`scorecard`](https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md) test from the Operator-SDK will be executed.
This is currently tested on [Kubernetes in Docker](https://github.com/kubernetes-sigs/kind) but should work on other Kubernetes systems as well.

## Prerequisites

You need the following installed on your local machine:

* Linux or macOS host
* Docker
* make
* KIND (if no existing Kubernetes cluster is available via `KUBECONFIG` or in `~/.kube/config`)

**Important:** Notice, that this script uses a container to execute the test. Your `KUBECONFIG` will be bind mounted into the container. Therefore no config-helpers or references to files on your host machine are allowed. This is usually the case for `minikube` or GKE clusters.

All further dependencies are encapsulated in a container image that this `Makefile` will execute as a test driver.

## Available test modes

The `Makefile` supports two test modes. Both have these supported options:

### Options:

` OP_PATH ` - relative path to your operator (required)

` OP_VER ` - version of operator (if not provided the latest will be determined from your `package.yaml`)

` OP_CHANNEL ` - channel of operator if is not provided it will be parsed by operator package yaml or use the default ones

` VERBOSE ` - enable verbose output of executed subcommands

### Linting metadata only

Using `operator-courier`, this test verifies your CSV and the package definition. More details can be found in the [docs](https://github.com/operator-framework/operator-courier). As part of this test nothing will be changed on your system.

Example, run from the top-level directory of this repository:

```
make operator.verify OP_PATH=upstream-community-operators/cockroachdb VERBOSE=1

Pulling docker image                              [  Processing  ]
Using default tag: latest
latest: Pulling from dmesser/operator-testing
Digest: sha256:457953575cd7bd2af60e55fb95f0413195e526c3bbe74b6de30faaf2f10a0585
Status: Image is up to date for quay.io/dmesser/operator-testing:latest
Pulling docker image                              [  OK  ]
Lint Operator metadata                            [  Processing  ]
WARNING: csv metadata.annotations.certified not defined. [2.0.9/cockroachdb.v2.0.9.clusterserviceversion.yaml]
WARNING: csv metadata.annotations.certified not defined. [2.1.1/cockroachdb.v2.1.1.clusterserviceversion.yaml]
Lint Operator metadata                            [  OK  ]

```

### Deploying and Testing your Operator

Using the [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager) (OLM) your Operator will be packaged into a temporary catalog, containing all currently published community operators and yours. OLM will be installed for you if not present.

Using the current community catalog as a base allows you to test with dependencies on Operators currently published in this catalog. If you have dependencies outside of this catalog, you need to prepare your own cluster, install OLM, and ship a catalog with these dependencies present; otherwise installation will fail. 
You can provide a Kubernetes cluster as a testbed via `KUBECONFIG` or `~/.kube/confg`. If you have multiple cluster contexts configured in your `KUBECONFIG` you will be able to select one. If you have no cluster configured or reachable the Makefile will install a `kind` cluster named `operator-test` for you.

For this type of test, additionally the following options exist:

` NO_KIND ` - if set to `1` no attempt to bring up a kind cluster will be made. In this case you need to specify `CATALOG_IMAGE`

` CATALOG_IMAGE ` - when `NO_KIND` is set to `1` you need to specify a container registry image location you have push privileges for and from which the image can be pulled again later by OLM without authentication. This parameter is ignored when `NO_KIND` is absent or set to `0` since the catalog image can be loaded directly into a KIND cluster.

` CLEAN_MODE ` - any of `NORMAL`, `NONE` and `FORCE`. As the test installs OLM components in your Kubernetes cluster this controls the clean up of those. In `NORMAL` clean up will happen if no errors occured. When set to `NONE` clean up is omitted. When set to `FORCE` clean up will always be done. Default is `NORMAL`.

` INSTALL_MODE ` - any of `OwnNamespace`, `SingleNamespace`, `AllNamespaces`. this controls the installation mode of the Operator and should be set according to what your Operator states as supported in the `installModes` section of the CSV. Default is `SingleNamepsace`.

You can start by just deploying your Operator:

```
make operator.install OP_PATH=upstream-community-operators/cockroachdb

Pulling docker image                              [  Processing  ]
Pulling docker image                              [  OK  ]
Find kube config                                  [  /home/dmesser/.kube/config  ]
Find kube cluster                                 [  Not found  ]
Start KIND                                        [  Processing  ]
Start KIND                                        [  OK  ]
Building catalog image                            [  Processing  ]
Building catalog image                            [  OK  ]
Operator version detected                         [  1.7.2  ]
Creating namespace                                [  Processing  ]
Creating namespace                                [  OK  ]
Verify operator                                   [  Processing  ]
Verify operator                                   [  OK  ]
Install OLM                                       [  Processing  ]
Install OLM                                       [  OK  ]
Building manifests                                [  Processing  ]
Building manifests                                [  OK  ]
Operator Deployment                               [  Processing  ]
    Applying object to cluster                    [  Processing  ]
    Applying object to cluster                    [  OK  ]
    Checking if subscriptions passes              [  Processing  ]
    Checking if subscriptions passes              [  OK  ]
    Checking if CSV passes                        [  Processing  ]
    Checking if CSV passes                        [  OK  ]
Operator Deployment                               [  OK  ]
```

This way you can test if your Operator is packaged correctly.

You can also run a test that will deploy your Operator and checks if it behaves correctly according to `scorecard` (which is part of the Operator-SDK). `scorecard` will use the example CRs defined in `metadata.annotations.alm-examples` in the CSV to try to use your Operator and observe its behavior.

Example, run from the top-level directory of this repository:

```
[...]

make operator.test OP_PATH=upstream-community-operators/cockroachdb

[...]
Instrumenting Operator for test                   [  Processing  ]
    creating CR files                             [  Processing  ]
    creating CR files                             [  OK  ]
    injecting scorecard proxy                     [  Processing  ]
    injecting scorecard proxy                     [  OK  ]
Instrumenting Operator for test                   [  OK  ]
Running scorecard trough all supplied CRs         [  Processing  ]
    Running required tests                        [  Processing  ]
    Running required tests                        [  OK  ]
    Running recommended tests                     [  Processing  ]
    Running recommended tests                     [  OK  ]
    Running required tests                        [  Processing  ]
    Running required tests                        [  OK  ]
    Running recommended tests                     [  Processing  ]
    Running recommended tests                     [  OK  ]
Running scorecard trough all supplied CRs         [  OK  ]
Cleaning up Operator resources                    [  Processing  ]
Cleaning up Operator resources                    [  OK  ]
Cleaning up Operator definition                   [  Processing  ]
Cleaning up Operator definition                   [  OK  ]
Cleaning up namespace                             [  Processing  ]
Cleaning up namespace                             [  OK  ]
```

## Troubleshooting

Here are some common scenarios, why your test can fail:

### Failures when linting Operator metadata

`ERROR: metadata.annotations.alm-examples contains invalid json string [1.4.4/my-operator.v1.4.4.clusterserviceversion.yaml]`

The linter checks for valid JSON in `metadata.annotations.alm-examples`. The rest of the CSV is supposed to be YAML.

### Failures when loading the Operator into the Community Catalog

`my-operator.v2.1.11 specifies replacement that couldn't be found`

Explanation: This happens because the catalog cannot load your Operator since it's pointing to a non-existent previous version of your Operator using `spec.replaces`. For updates, it is important that this property points to another, older version of your Operator that is already in the catalog.

`error adding operator bundle : error decoding CRD: no kind \"CustomResourceDefinition\" is registered for version \"apiextensions.k8s.io/v1\" in scheme \"pkg/registry/bundle.go`

Explanation: Currently OLM does not yet support handling CRDs using `apiextensions.k8s.io/v1`. This will improve soon. Until then you need to resort back to `apiextensions.k8s.io/v1beta`.

`error loading manifests from directory: error checking provided apis in bundle : couldn't find charts.someapi.k8s.io/v1alpha1/myapi (my-custom-resource) in bundle. found: map[]`

Explanation: Your Operator claims ownership of a CRD that it does not ship. Check for spelling of Group/Version/Kind in `spec.customresourcedefinitions.owned` in the CSV.

`error loading package into db: [FOREIGN KEY constraint failed, no default channel specified for my-operator]`

Explanation: This happens when either
- Your Operator package defines more than one channel in `package.yaml` but does not define `defaultChannel`.
- The package just defines a single channel (in which case you can omit `defaultChannel`) but the catalog couldn't load the CSV that this channel points to using `currentCSV`. This can happen when in the CSV the specified name in `metadata.name` is actually different from what `currentCSV` points to.

### Failures when deploying via OLM

`Check if subscription passes` times out

Explanation: In this case the `Subscription` object created by the test suite did not transition to the state `AtLatestKnown` before hitting a timeout. There are various reasons for this, ranging from the catalog pod crashing to problems with the `catalog-operator` pod of OLM itself. In any case, the logs of either pod will likely help troubleshooting and finding the root cause.

`Check if CSV passes` times out

Explanation: OLM could not install the Operator's `Deployment` from its CSV before hitting a timeout. This is usually due to `Deployment` reaching its expected replica count, likely because the pod is crash-looping.

### Failures during tests of the Operator with Operator-SDK scorecard

`failed to get proxyPod: timed out waiting for the condition:`

Explanation: If this happened it is likely the Operator pod crashed in the middle of the scorecard test suite. For example, when it failed to parse a Custom Resource fed to scorecard from the list in `metadata.annotations.alm-examples`. OLM will wait for the `Deployment` of the Operator to recover before re-installing the Operator. Re-installation changes the Operator pod's name and hence scorecard fails to reach the logs of scorecard proxy using its old name.

`failed to create cr resource: object is being deleted: someapi.k8s.io "myCRD" already exists:`

Explanation: This can happen when your Operator automatically creates a CR on startup, with the same name of an example for that CR provided in the CSV `metadata.annotations.alm-examples` section. Simply use a different name in the example. Otherwise, your Operator could be slow to delete a CR due to a finalizer.

## Additional shortcuts

### Clean up after a failed test

As explained above, the default `CLEAN_MODE` of `NORMAL` will delete anything that got installed on your cluster if all tests run correctly.. If something fails, the deployed resources will not be deleted in order to give you a chance to debug.
After you have finished debugging you can use the following command to clean up any residual resources as part of a test of a particular Operator:

```
make operator.cleanup OP_PATH=upstream-community-operators/cockroachdb
```

### Install a KIND cluster
Install a `kind` cluster as a testbed for the Operator deployment.

```
$ kind create cluster --name operator-test
```

This command will create a Kubernetes in Docker cluster:

```
$ kind get clusters                     
operator-test

$ kind get nodes --name operator-test
operator-test-control-plane
```

### Install Operator Lifecycle Manager
Install OLM to an existing cluster (determined via `KUBECONFIG` or `~/.kube/config`).
```
make olm.install
```

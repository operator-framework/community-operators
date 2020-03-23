# Automate testing your Operator locally

For convenience, in addition to the [manual test instructions](./testing-operators.md) we provide a `Makefile` based test automation. This will automate all the manual steps referred to in [Testing Operator Deployment on Kubernetes](./testing-operators.md#testing-operator-deployment-on-kubernetes). In addition the [`scorecard`](https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md) test from the Operator-SDK will be executed.
This is currently tested on [Kubernetes in Docker](https://github.com/kubernetes-sigs/kind) but should work on other Kubernetes systems as well.

## Prerequisites

You need the following installed on your local machine:

* Linux or macOS host
* Docker
* make
* KIND (if no existing Kubernetes cluster is available via `KUBECONFIG` or in `~/.kube/config`)

All further dependencies are encapsulated in a container image that this `Makefile` will execute as a test driver.

## Available test modes

The `Makefile` supports two test modes. Both have these supported options:

### Options:

` OP_PATH ` - relative path to your operator (required)

` OP_VER ` - version of operator (if not provided the latest will be determined from your `package.yaml`)

` OP_CHANNEL ` - channel of operator if is not provided it will be parsed by operator package yaml or use the default ones

` VERBOSE ` - enable verbose output of executed subcommands

### Linting metadata only
Using `operator-courier` this test verify your CSV and the package definitionmore detail in the [docs](https://github.com/operator-framework/operator-courier). As part of this test nothing will be changed on your system.

Example, run from the top-level directory of this repository:

```
make operator.verify OP_PATH=upstream-community-operators/cockroachdb VERBOSE=1

Pulling docker image                              [  Processing  ]
Using default tag: latest
latest: Pulling from dmesser/operator-testing
Digest: sha256:457953575cd7bd2af60e55fb95f0413195e526c3bbe74b6de30faaf2f10a0585
Status: Image is up to date for quay.io/operator-framework/operator-testing:kind:latest
Pulling docker image                              [  OK  ]
Verify operator                                   [  Processing  ]
WARNING: csv metadata.annotations.certified not defined. [2.0.9/cockroachdb.v2.0.9.clusterserviceversion.yaml]
WARNING: csv metadata.annotations.certified not defined. [2.1.1/cockroachdb.v2.1.1.clusterserviceversion.yaml]
Verify operator                                   [  OK  ]

```

### Deploying and Testing your Operator
Using the [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager)(OLM) your Operator will be packaged into a temporary catalog and installation will be attempted. OLM will be installed for you if not present.
You can either provide an Kubernetes cluster as a testbed via `KUBECONFIG` or `~/.kube/confg`. If you have multiple cluster context configured in your `KUBECONFIG` you will be able to select one. If you have no cluster configured or reachable the Makefile will install a `kind` cluster named `operator-test` for you

For this type of test, additionally the following options exist:

` NO_KIND ` - if set to `1` no attempt to bring up a kind cluster will be made

` CLEAN_MODE ` - any of `NORMAL`, `NONE` and `FORCE`. As the test installs OLM components in your Kubernetes cluster this controls the clean up of those. In `NORMAL` clean up will happen if no errors occured. When set to `NONE` clean up is ommitted, when set to `FORCE` clean up will always be done. Default is `NORMAL`.

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

You can also run a test that will deploy your Operator and checks if it behaves correctly according to `scorecard` (which is part of the Operator-SDK).

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

## Additional shortcuts

### Clean up after a failed test

Like explained above (`CLEAN_MODE`), by default, if all tests run correctly, anything that got installed of on your cluster as part of the test will be deleted. If something fails, the deployed resource will not be deleted in order to give you a chance to debug.
After you finished debugging you can use the following command to clean up any residual resources as part of a test of a particular Operator:

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

### Install operator lifecycle manager
Install OLM to an existing cluster (determined via `KUBECONFIG` or `~/.kube/config`).
```
make olm.install
```
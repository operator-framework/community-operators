# Automate testing your Operator locally

For convenience, in addition to the [manual test instructions](./testing-operators.md) we provide a `Makefile` based test automation. This will automate all the manual steps referred to in [Testing Operator Deployment on Kubernetes](./testing-operators.md#testing-operator-deployment-on-kubernetes). In addition the [`scorecard`](https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md) test from the Operator-SDK will be executed.
This is currently tested on `minikube` but should work on other Kubernetes systems as well.

## Prerequisites

You need the following installed on your local machine:

* Linux or macOS host
* Docker
* make
* minikube (if no existing Kubernetes cluster is available via `KUBECONFIG` or in `~/.kube/config`)

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
make operator.verify OP_PATH=upstream-community-operators/cockroachdb

Verify operator                                   [  Processing  ]
WARNING: csv metadata.annotations.certified not defined. [cockroachdb/cockroachdb.v2.1.1.clusterserviceversion.yaml]
WARNING: csv metadata.annotations.certified not defined. [cockroachdb/cockroachdb.v2.0.9.clusterserviceversion.yaml]
Verify operator                                   [  OK  ]
```

### Deploying and Testing your Operator
Using the [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager)(OLM) your Operator will be packaged into a temporary catalog and installation will be attempted. OLM will be installed for you if not present.
You can either provide an Kubernetes cluster as a testbed via `KUBECONFIG` or `~/.kube/confg` or the Makefile will install a `minikube` cluster for you. 

For this type of test, additionally the following options exist:

` VM_DRIVER ` - VM_DRIVER flag passed to `minikube` in case no existing cluster was supplied. Default is determined by your `minikube` install.

` CLEAN_MODE ` - any of `NORMAL`, `NONE` and `FORCE`. As the test installs OLM components in your Kubernetes cluster this controls the clean up of those. In `NORMAL` clean up will happen if no errors occured. When set to `NONE` clean up is ommitted, when set to `FORCE` clean up will always be done. Default is `NORMAL`.

` INSTALL_MODE ` - any of `OwnNamespace`, `SingleNamespace`, `AllNamespaces`. this controls the installation mode of the Operator and should be set according to what your Operator states as supported in the `installModes` section of the CSV. Default is `SingleNamepsace`.

You can start by just deploying your Operator:

```
minikube start
[...]

make operator.install OP_PATH=upstream-community-operators/cockroachdb

Pulling docker image                              [  Processing  ]
Pulling docker image                              [  OK  ]
cluster is running and ready for installing olm   [  OK  ]
Find kube config                                  [  CONTEXT: minikube  ]
Operator version detected                         [  2.1.11  ]
Creating namespace                                [  Processing  ]
Creating namespace                                [  OK  ]
Verify operator                                   [  Processing  ]
WARNING: csv metadata.annotations.certified not defined. [cockroachdb/cockroachdb.v2.1.1.clusterserviceversion.yaml]
WARNING: csv metadata.annotations.certified not defined. [cockroachdb/cockroachdb.v2.0.9.clusterserviceversion.yaml]
Verify operator                                   [  OK  ]
Install OLM                                       [  Processing  ]
Install OLM                                       [  OK  ]
Make registry configmap                           [  Processing  ]
    creating subscription files                   [  OK  ]
    creating operator group file                  [  OK  ]
    creating CR file                              [  OK  ]
    creating kubeconfig secret file               [  OK  ]
    creating kubeconfig volume file               [  OK  ]
    creating kubeconfig secret mount              [  OK  ]
    creating config map registry                  [  OK  ]
Make registry configmap                           [  OK  ]
Operator deployment                               [  Processing  ]
    Apply OPERATOR GROUP file                     [  OK  ]
    Applying object to cluster                    [  Processing  ]
    Applying object to cluster                    [  OK  ]
    Checking subscriptions if passes              [  Processing  ]
    Checking subscriptions if passes              [  OK  ]
    Checking csv if passes                        [  Processing  ]
    Checking csv if passes                        [  OK  ]
    Waiting for deployment                        [  Processing  ]
    Waiting for deployment                        [  OK  ]
Operator deployment                               [  OK  ]
```

This way you can test if your Operator is packaged correctly.

You can also run a test that will deploy your Operator and checks if it behaves correctly according to `scorecard` (which is part of the Operator-SDK).

Example, run from the top-level directory of this repository:

```
minikube start
[...]

make operator.test OP_PATH=upstream-community-operators/cockroachdb

[...]
Operator deployment                               [  OK  ]
Test operator with scorecard                      [  Processing  ]
Running scorecard trough all CR


Running operator-sdk scorecard against /tmp/tmp.DnJhFA/deploy/cockroachdb/2.1.11/cockroachdb.v2.1.11.clusterserviceversion.yaml with /tmp/tmp.DnJhFA/deploy/crs/XXXXNcblLd.cr.yaml
DEBU[0000] Debug logging is set
WARN[0000] Could not load config file; using flags
WARN[0000] Plugin directory not found; skipping external plugins: stat scorecard: no such file or directory
Basic Tests:
	Spec Block Exists: 1/1
	Status Block Exists: 1/1
	Writing into CRs has an effect: 1/1
OLM Tests:
	Owned CRDs have resources listed: 1/1
	CRs have at least 1 example: 1/1
	Spec fields with descriptors: 0/28
	Status fields with descriptors: 0/2
	Provided APIs have validation: 0/0

Total Score: 69%
SUGGESTION: If it would be helpful to an end-user to understand or troubleshoot your CR, consider adding resources [namespaces/v1 poddisruptionbudgets/v1beta1 statefulsets/v1beta1 jobs/v1 cockroachdbs/v1alpha1] to the resources section for owned CRD Cockroachdb
SUGGESTION: Add a spec descriptor for ExternalHttpPort
SUGGESTION: Add a spec descriptor for Image
SUGGESTION: Add a spec descriptor for PodManagementPolicy
SUGGESTION: Add a spec descriptor for Replicas
SUGGESTION: Add a spec descriptor for ExternalGrpcName
SUGGESTION: Add a spec descriptor for ImageTag
SUGGESTION: Add a spec descriptor for NetworkPolicy
SUGGESTION: Add a spec descriptor for Tolerations
SUGGESTION: Add a spec descriptor for UpdateStrategy
SUGGESTION: Add a spec descriptor for ImagePullPolicy
SUGGESTION: Add a spec descriptor for NodeSelector
SUGGESTION: Add a spec descriptor for Resources
SUGGESTION: Add a spec descriptor for Secure
SUGGESTION: Add a spec descriptor for StorageClass
SUGGESTION: Add a spec descriptor for Component
SUGGESTION: Add a spec descriptor for HttpName
SUGGESTION: Add a spec descriptor for InternalHttpPort
SUGGESTION: Add a spec descriptor for Service
SUGGESTION: Add a spec descriptor for InitPodResources
SUGGESTION: Add a spec descriptor for Storage
SUGGESTION: Add a spec descriptor for ClusterDomain
SUGGESTION: Add a spec descriptor for InternalGrpcName
SUGGESTION: Add a spec descriptor for MaxSQLMemory
SUGGESTION: Add a spec descriptor for Name
SUGGESTION: Add a spec descriptor for CacheSize
SUGGESTION: Add a spec descriptor for ExternalGrpcPort
SUGGESTION: Add a spec descriptor for InternalGrpcPort
SUGGESTION: Add a spec descriptor for MaxUnavailable
SUGGESTION: Add a status descriptor for conditions
SUGGESTION: Add a status descriptor for deployedRelease
Test operator with scorecard                      [  OK  ]
```

## Additional shortcuts

### Clean up after a failed test

Like explained above (`CLEAN_MODE`), by default, if all tests run correctly, anything that got installed of on your cluster as part of the test will be deleted. If something fails, the deployed resource will not be deleted in order to give you a chance to debug.
After you finished debugging you can use the following command to clean up any residual resources as part of a test of a particular Operator:

```
make operator.cleanup OP_PATH=upstream-community-operators/cockroachdb
```

### Install a minikube cluster
Install a `minikube` cluster as a testbed for the Operator deployment. Supply `VM_DRIVER` to amend which of the supported hypervisors is used.

```
make minikube.install VM_DRIVER=hyperkit
```

This command will create a minikube cluster under the profile `operators`:

```
$ minikube status --profile operators

host: Running
kubelet: Running
apiserver: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.64.101
```

### Install operator lifecycle manager
Install OLM to an existing cluster (determined via `KUBECONFIG` or `~/.kube/config`).
```
make operator.olm.install
```

## Troubleshooting


### minikube.start permission denied
- if you starting minikube without VM_DRIVER you need have proper setup for docker which can be run without sudo and
now is not possible without sudo because [issue](https://github.com/kubernetes/minikube/issues/3718) you can run `sudo make minikube.start` or add VM_DRIVER


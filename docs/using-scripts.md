# Pulling from quay.io

## Prerequisites
The following prequistis are required run to the quay.io scripts:

* [jq](https://stedolan.github.io/jq/) must be installed
* A quay.io account

To pull your operator from quay.io, simply run the following command:
```bash
$ scripts/pull-from-quay $NAMESPACE $REPOSITORY
```

In the command above, `$NAMESPACE` is the [quay.io](https://quay.io) namespace. Possible values include:

* [community-operators](https://quay.io/organization/community-operators)
* [upstream-community-operators](https://quay.io/organization/upstream-community-operators)
* your personal quay.io namespace.

The `$REPOSITORY` is the name of the folder you created under the `$NAMESPACE` directory.

For example, for `community-operators/etcd` the `$NAMESPACE` would be `community-operators` and the `$REPOSITORY` would be `etcd`.

# Testing operator locally

## Prerequisites

You need have installed docker and make 

## Check operator with courrier only
operator currier verify your CSV more detail in [docs](https://github.com/operator-framework/operator-courier)

Community operator check:

```
make operator.verify
```

### Options:

` OP_PATH ` - relative path to your operator which is required

` OP_VER ` - version of operator if is not provided it will be parsed by operator package yaml

` VERBOSE ` - enable logging

## Install operator lifecycle manager
Install OLM to your cluster it will be installed with `kubectl` with your local config

```
make operator.olm.install
```

## Run scorecard operator
You need run the minikube or have some kubernetes instance configured.
If you want test it in minikube which will be automatically started if you don't have any kubeconfig in home directory or you can run it manually: 

```
make minikube.start VM_DRIVER=kvm2
```

### Options:

` VM_DRIVER ` - it's driver for minikube if you need start one

If you want test your operator against scorecard and operator courrier, which check the dependency and also run minikube if you don't have any kubeconfig available.

```
make operator.test OP_PATH=community-operators/your-operator OP_VER=0.0.1 VERBOSE=1
``` 

### Options:

` OP_VER ` - version of operator if is not provided it will be parsed by operator package yaml

` OP_CHANNEL ` - channel of operator if is not provided it will be parsed by operator package yaml or use the default ones
 
` OP_PATH ` - relative path to your operator which is required

` CLEAN_MODE ` - define how tooling clear your operators and pods, `FORCE` - clear whole namespace no matter what, `NONE` - don't clear anything, `NORMAL` - clear it if your test passed, if something failed namespace with all pods and configs will be stay for debugging
 
` VERBOSE ` - enable logging

## Troubleshooting

### minikube.start permission denied
- if you starting minikube without VM_DRIVER you need have proper setup for docker which can be run without sudo and
now is not possible without sudo because [issue](https://github.com/kubernetes/minikube/issues/3718) you can run `sudo make minikube.start` or add VM_DRIVER


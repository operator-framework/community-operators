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

* [redhat-operators](https://quay.io/organization/redhat-operators)
* [community-operators](https://quay.io/organization/community-operators)
* your personal quay.io namespace.

The `$REPOSITORY` is the name of the folder you created under the `$NAMESPACE` directory.

For example, for `community-operators/etcd` the `$NAMESPACE` would be `community-operators` and the `$REPOSITORY` would be `etcd`.

# Testing operator locally

## Prerequisites
You can check the prerequisites with make script:
```
make dependencies.check
```

it is option there to install all detected missing dependencies

It will be also check if you run test command

### Options:

` INSTALL_DEPS ` - if you set it to `1` you automatically install the dependencies without prompt

## Manual installation missing dependencies
If you miss something we prepare install script for needed dependencies:

```
make dependencies.install.missing_dependencies
```

## Check operator with courrier only
operator currier verify your CSV more detail in [docs](https://github.com/operator-framework/operator-courier)

Community operator check:

```
make operator.verify
```

### Options:

` OP_PATH ` - relative path to your operator which is required

## Build registry image
Build registry with your local version of operators, it also will be pushed if you specify ` REG_IMAGE `

```
make operator.registry.build
```

### Options:

` OP_PATH ` - relative path to your operator which is required

` OP_VER ` - version of operator if is not provided it will be parsed by operator package yaml

` REG_IMAGE ` - registry image which will be use while testing operator and there will be pushed image with registry with your operator (it's required if you provide VM_DRIVER or when you start test in existing cluster)

## Install operator lifecycle manager
Install OLM to your cluster it will be installed with `kubectl` with your local config

```
make operator.olm.install
```

## Run scorecard operator
You need run the minikube or have some kubernetes instance configured.
If you want test it in minikube which will be automatically started if you don't have any kubeconfig in home directory or you can run it manually: 

```
make minikube.start
```

If you want test your operator against scoreboard and operator courrier, which check the dependency and also run minikube if you don't have any kubeconfig available.

```
make operator.test OP_PATH=community-operators/your-operator OP_VER=0.0.1 VM_DRIVER=kvm2 VERBOSE=1
``` 

### Options:

` OP_VER ` - version of operator if is not provided it will be parsed by operator package yaml
 
` OP_PATH ` - relative path to your operator which is required

` VM_DRIVER ` - it's driver for minikube if you need start one

` REG_IMAGE ` - registry image which will be use while testing operator and there will be pushed image with registry with your operator (it's required if you provide VM_DRIVER or when you start test in existing cluster)

` VERBOSE ` - enable logging
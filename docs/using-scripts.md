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

# Testing operator localy

## Prerequisites
You can check the prerequisites with make script:
```
make dependencies.check
```

It will be also check if you run test command

## Install missing dependencies
If you miss something we prepare install script for needed dependencies:

```
make dependencies.install.missing_dependencies
```

## Check operator with courrier only
Community operator check:

```
make operator.verify
```

## Run scorecard operator
You need run the minikube or have some kubernetes instance configured.
If you want test it in minikube which will be automaticaly started if you don't have any kubeconfig in home directory or you can run it manualy: 

```
make minikube.start
```

If you want test your operator agains scoreboard and operator courrier, which check the dependency and also run minikube if you don't have any kubeconfig available.

```
make operator.test OP_PATH=community-operators/your-operator OP_VER=0.0.1 VM_DRIVER=kvm2
``` 

## If you run in existing instance of kubernetes or VM minikube

you also need specify your image to push bundled operator registry

```
make  operator.test OP_PATH=community-operators/your-operator OP_VER=0.0.1 REG_IMAGE=operator-registry-image
```

if you need or want run minikube with vm driver other then default you can specify it

```
make minikube.start VM_DRIVER=kvm2
```
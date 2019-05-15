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

## Install missing dependencies
If you miss something we prepare install script for needed dependencies:

```
make dependencies.install.missing_dependencies
```

## Check operator with courrier
Community operator check:

```
make operator.community.verify
```

Upstream operator check: 

```
make operator.upstream.verify
```

## Run scorecard operator
firstly you need run the minikube

```
make minikube.start
```

and then run your scoreboard on your operator in minikube

```
make operator.test OP_PATH=community-operators/your-operator OP_VER=0.0.1
``` 

if you need or want run minikube with vm driver other then default you can specify it

```
make minikube.start VM_DRIVER=kvm2
```

but you also need specify your image to push bundled operator registry

```
make  operator.test OP_PATH=community-operators/your-operator OP_VER=0.0.1 REG_IMAGE=quay.io/operator-registry
```
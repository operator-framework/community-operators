# Pulling from quay.io

##Prerequisites
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
# Testing Operators

This guide is targeted towards operator authors who are targetting their operators to be available on OpenShift 4.0
clusters through OperatorHub and want to test that end to end workflow.

## Testing the full end-to-end flow

### Pre-Requisite

You need to have an account with `quay.io`. If you don't have one you can sign up for it at [quay.io](https://quay.io).

### Create your Quay app-registry repository

OperatorHub uses Quay's application repositories for storing the operator bundle. Follow [these instructions](https://docs.quay.io/guides/create-repo.html)
to create your own application repository. Please note that the name of the repository should match the name of the
operator in it's package. Example: for the following package, the Quay repository name will be `myoperator`:
```
packageName: myoperator
channels:
- name: preview
  currentCSV: myoperator.0.1.1
```

### Pushing your operator bundle to Quay

Collect all your operator bundles files into a directory. You can then use the
[operator-courier](https://github.com/operator-framework/operator-courier/#usage)
tool to verify and push your operator bundle to the Quay application repository you created.

Please note that we only support CRDs, CSVs and Packages to be present in your bundle.

### Linking the Quay application repository to your OpenShift 4.0 cluster

For OpenShift to become aware of the Quay application repository, an
[`OperatorSource` CR](https://github.com/operator-framework/operator-marketplace#description)
need to be added to the cluster. An example `OperatorSource` is provided [here](https://github.com/operator-framework/operator-marketplace/blob/master/deploy/examples/community.operatorsource.cr.yaml).
If your Quay repository is private, please follow [these](https://github.com/operator-framework/operator-marketplace/blob/master/docs/how-to-authenticate-private-repositories.md) instructions.

### Testing your operator

Once the `OperatorSource` CR has been added to the cluster, the new operator will show up on the OperatorHub UI. You can
then either install it from the UI or follow the command line [instructions](https://github.com/operator-framework/operator-marketplace#installing-an-operator-using-marketplace).

# Operator release
## Operator release workflow

[Release workflow](https://github.com/operator-framework/community-operators/actions?query=workflow%3A%22Operator+release%22) contains all jobs. This can be found in action tab of the project.

![Release workflow](images/op_action_release.png)

When operator is merged to master following scenarios will happen: 
## For k8s case (upstream-community-operators)

1. Push to quay (to support old app registry)
1. Build index image for k8s
1. Build image image for operatorhub.io page
1. Deploy operatorhub.io page

![k8s release summary](images/op_release_k8s.png)

## For openshift case (community-operators)

1. Push to quay (to support old app registry)
1. Build index image for different openshift versions (v4.6 and v4.7 in this case) and multiarch image is also is produced.
1. Build image image for dev.operatorhub.io page (for development purposes only)
1. Deploy dev.operatorhub.io page (for development purposes only)

![openshift release summary](images/op_release_o7t.png)

## Operator is published
After this process, your operator will be published.

### Index image location

For Openshift: 

`registry.redhat.io/redhat/community-operator-index:v4.6`
`registry.redhat.io/redhat/community-operator-index:v4.7`
`registry.redhat.io/redhat/community-operator-index:latest` - this is a clone of `v4.6` from historical reasons as it always was a clone of `v4.6`. Will be deprecated in the future.

For Kubernetes:

`quay.io/operatorhubio/catalog:latest`

### Bundle images location
For Openshift:

`quay.io/openshift-community-operators/`

For Kubernetes:

`quay.io/operatorhubio/`
# Operator deployment
When operator is merged to master following scenarios will happen: 

## For k8s case (upstream-community-operators)

1. Push to quay (to support old app registry)
1. Build index image for k8s
1. Build image image for operatorhub.io page
1. Deploy operatorhub.io page

![Catalog history](images/op_release_k8s.png)

## For openshift case (community-operators)

1. Push to quay (to support old app registry)
1. Build index image for different openshift versions (v4.6 and v4.7 in this case) and multiarch image is also is produced.
1. Build image image for dev.operatorhub.io page (for development purposes only)
1. Deploy dev.operatorhub.io page (for development purposes only)

![Catalog history](images/op_release_o7t.png)

## Operator is publisked
After this process your operator should be published.
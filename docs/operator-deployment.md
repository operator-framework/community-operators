# Operator deployment
When operator is merged to master following jobs are done:

1. Push to quay (to support old app registry)
1. Triggering operator deployment to project `operator-framework/community-operator-catalog` project

![Catalog history](images/op_after_merge_01.png)

Project `operator-framework/community-operator-catalog` is used to build catalog images in sequential fashion to prevent race condition when catatlog is built. One can see full history [here](https://travis-ci.com/github/operator-framework/community-operator-catalog/builds)

![Catalog history](images/op_deploy_build_history.png)

The deployment looks like this

![Catalog history](images/op_deploy_overview.png)

It consists of following steps

1. Building bunde and index
1. Build image for operatorhub.io page (only for kubernetes-operator)
1. Trigger to build operatorhub.io (only for kubernetes-operator)



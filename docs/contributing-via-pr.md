# Submitting your Operator via Pull Requests (PR)

## Fork community operators project
To submit an operator one has to do two steps

1. Fork project `https://github.com/operator-framework/community-operators`
1. Make a pull request
1. Place the operator in the target directory
  - community-operators (OpenShift operator)
  - upstream-community-operators (Kubernetes operator)

## Pull request
When a pull request is created, a number of tests are executed. One can see the results in `Travis CI - Pull Request `.

![PR Test results](images/op_pr_01.png)

## Test results via Travis jobs
There are multiple tests. For easy mapping different fruit names were chosen.
One can see more details about tests when clicking on `Details`. This will redirect to the following page

![Test results](images/op_travis_01.png)

and via Travis UI

![Test results](images/op_travis_02.png)

### Kiwi test
Full operator tests

- Building bundle image
    - from packagemanifest format
    - from bundle format
- Sanity check of operator version (when multiple, only last test is done)
- Validation using `operator-sdk validate`
- Building temporary catalog with one operator version in it
- Deployment of operator on kind (k8s) cluster (only for kuberbetes-operator)

### Lemon test
Test if operator can be added to index from scratch

- Build all bundle images
- Build catalog

### Orange test
Test if operator can be added to index from existing bundles from production (quay.io)

- Build current operator version locally
- Use older versions from quay.io
- Build catalog

!!! note
    It might happen that the operator version is already published and in this case the label `allow/operator-version-overwrite` has to be set (ask mantainers)

#### Operator version overwrite
When cosmetic changes are made to an already published operator version, the `Orange` test will fail. See Note above.

After the PR is merged, the following changes will happen

- Bundle for current operator version will be overwritten
- Build catalog with new bundle

#### Operator recreate
When a whole operator is recreated (usually when converting a whole operator from packagemanifest format to bundle format), one needs to have the `allow/operator-recreate` label set. One can set it or ask a maintainer to set it for you.

After the PR is merged, the following changes will happen

- Delete operator
- Rebuild all bundles
- Build catalog with new bundles


## Test on openshift cluster
For an OpenShift operator the test is executed on an OpenShift cluster via `ci/prow/deploy-operator-on-openshift`.

!!! note
    The `kiwi` test does not include the same test on a Kubernetes cluster in the Travis job. This can be forced by specifiyng label `test/force-deploy-on-kubernetes` in the PR.

# More information
More detailed information about our Continuous Integration process can be found [here](./ci.md)

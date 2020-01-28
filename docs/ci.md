## PR Continuous Integration

Operators submitted to this repo are automatically tested on a Kubernetes cluster before being merged. The Kubernetes distribution used for testing depends on which directory the operator is submitted to. Ideally all tests should pass before merging.

### CI test scripts

Operators are tested using several scripts found in the [`scripts/ci/`][scripts-ci] directory. When a PR is updated or modified, the CI configuration calls `scripts/ci/test-pr`, which calls `scripts/ci/test-operator` and `scripts/ci/verify-operator` for each operator updated in a PR that meets directory requirements for that CI environment. `test-operator` has two main functions: deploy an operator on the cluster using the [OLM][olm], and test the operator using the [scorecard][sdk-scorecard]. `verify-operator` runs [`operator-courier verify`][courier-verify] on an operators' [bundle][registry-bundle].

**Note**: CI test results do not explicitly prevent your operator from being merged _yet_. Test results will be used by PR reviewers to suggest changes before submission.

#### OLM

Deployment with the OLM involves creating several required manifest files to create `CustomResourceDefinitions` (CRD's) and the operators' `Deployment` using its `ClusterServiceVersion` (CSV) in-cluster. `test-operator` will create a [`operator-registry`][registry] Docker image containing the operators' bundled manifests, and `CatalogSource` and `Subscription` manifests that allow the OLM to find the registry image and deploy a particular CSV from the registry, respectively.

Failure to successfully deploy an operator using the OLM results in test failure, as all operators are expected to be deployable in this manner.

#### Scorecard

The [Operator SDK scorecard][sdk-scorecard] suggests modifications applicable to an operator based on development best-practices. The scorecard runs static checks on operator manifests and runtime tests to ensure an operator is using cluster resources correctly. A Custom Resource (CR) is created by the scorecard for use in runtime tests, so [`alm-examples`][olm-alm-examples] must be populated.

The scorecard assigns points to each passing component of the scorecard. The total number of points is a function of several factors, ex. number of CRD's, but a weighted total percentage is calculated for the overall test run. It is possible to get a score of 100%, but operators are not expected to achieve this.

`test-operator` injects a scorecard proxy container and volume into an operators' CSV manifest before deployment; this is necessary to get API server logs, from which the scorecard determines runtime test results. These modifications are not persistent, as they're only needed for testing.

**Note**: no explicit number of points or percentage is necessary to achieve before merging _yet_. These are suggestions to improve your operator.

#### operator-courier

The [`operator-courier verify`][courier] command verifies that a set of files is valid and can be bundled and pushed to [quay.io][quay]. Read the [docs][courier-docs] for more information.

### Upstream operators

Operators submitted to the `upstream-community-operators/` directory are tested against a [`minikube`][minikube] instance deployed on a [Travis CI][travis-ci] environment. The OLM is installed locally in this case.

### OpenShift operators

Operators submitted to the `community-operators/` directory are tested against an OpenShift 4.0 cluster deployed on AWS using the [`ci-operator`][ci-operator].

[olm]:https://github.com/operator-framework/operator-lifecycle-manager/
[sdk-scorecard]:https://github.com/operator-framework/operator-sdk/blob/master/doc/test-framework/scorecard.md
[courier]:https://github.com/operator-framework/operator-courier/
[minikube]:https://kubernetes.io/docs/setup/minikube/
[travis-ci]:https://travis-ci.org/
[ci-operator]: https://github.com/openshift/release/tree/master/ci-operator
[scripts-ci]:../scripts/ci/
[registry-bundle]:https://github.com/operator-framework/operator-registry#manifest-format
[courier-verify]:https://github.com/operator-framework/operator-courier/#command-line-interface
[registry]:https://github.com/operator-framework/operator-registry
[olm-alm-examples]:https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/building-your-csv.md#crd-templates
[courier-docs]:https://github.com/operator-framework/operator-courier/#operator-courier
[quay]:https://quay.io
[quay-create-repo]:https://docs.quay.io/guides/create-repo.html
[operator-courier]:https://github.com/operator-framework/operator-courier/#usage
[operatorsource-cr]:https://github.com/operator-framework/operator-marketplace#description
[operatorsource-cr-example]:https://github.com/operator-framework/operator-marketplace/blob/master/deploy/examples/community.operatorsource.cr.yaml
[marketplace-private-repo]:https://github.com/operator-framework/operator-marketplace/blob/master/docs/how-to-authenticate-private-repositories.md
[marketplace-install]:https://github.com/operator-framework/operator-marketplace#installing-an-operator-using-marketplace


## Testing your operator by CI
If you want test your operator by CI, you have two option in all supported CI. Test it against minikube or your own cluster by providing kubeconfig 

### Supported CI
 
 - [Travis](#travis)
 - [Gitlab](#gitlab)
 - [Jenkins](#jenkins)
 
### Travis

#### Minikube

Setting up travis ci against minikube have minimal setup you need copy `.travis.yml` from [.travis.yml](./ci-templates/.travis.yml) 
to your repository and setup `OP_PATH` variable inside the script to make sure that point to your operator manifests.

#### Existing cluster

For setting up travis against existing cluster you need provide your `KUBECONFIG` encoded by base64 to your travis env variables
and copy [.travis_with_kubeconfig.yml](./ci-templates/.travis_with_kubeconfig.yml) to your repository as `.travis.yml` and also need configure `OP_PATH` 
to make sure that point to your operator manifests

### Gitlab

#### Minikube

##### Requirements
standalone ci runner installed and registered by guide: 
- [install](https://docs.gitlab.com/runner/install/)
- [register](https://docs.gitlab.com/runner/register/index.html)

on VM you have to install:
- [docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
  - add privilages to manage docker ` sudo usermod -aG docker gitlab-runner`
- install virutalbox and change vm-driver to virtual box or allow gitlab runner the priviliges by:
  - `sudo usermod -a -G sudo gitlab-runner`
  - `sudo visudo` and add line on end `gitlab-runner ALL=(ALL) NOPASSWD: ALL (This is required only if you using minikube)

Setting up travis ci against minikube have minimal setup you need copy `.gitlab-ci.yml` from [.gitlab-ci.yml](./ci-templates/.gitlab-ci.yml) 
to your repository and setup `OP_PATH` variable inside the script to make sure that point to your operator manifests.

#### Existing cluster

##### Requirements
Make sure that your runner can use docker

For setting up travis against existing cluster you need provide your `KUBECONFIG` encoded by base64 to your gitlab CI/CD variables
and copy [.gitlab-ci.yml](./ci-templates/.gitlab-ci_with_kubeconfig.yml) to your repository as `.gitlab-ci.yml` and also need configure `OP_PATH` 
to make sure that point to your operator manifests


### Jenkins

#### Minikube

##### Requirements
on VM you have to install:

(https://docs.docker.com/install/linux/docker-ce/ubuntu/)[docker]

add privilages to manage docker sudo usermod -aG docker jenkins

Also you need install minikube:

```
 curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
 chmod +x minikube && mv minikube /usr/bin/
```
and need add to suders file line: (Or you can use virutalbox or KVM2 as virtualization driver without sudo)
```
jenkins hostname = (root) NOPASSWD: /usr/bin/minikube
```


Setting up travis ci against minikube have minimal setup you need copy `Jenkinsfile` from [Jenkinsfile](./ci-templates/Jenkinsfile) 
to your repository and setup `OP_PATH` variable inside the script to make sure that point to your operator manifests.

#### Existing cluster

##### Requirements
on VM you have to install:

(https://docs.docker.com/install/linux/docker-ce/ubuntu/)[docker]

add privilages to manage docker sudo usermod -aG docker jenkins

For setting up travis against existing cluster you need provide your `KUBECONFIG` encoded by base64 to your Jenkins env variables
and copy [Jenkinsfile](./ci-templates/Jenkinsfile_with_kubeconfig) to your repository as `Jenkinsfile` and also need configure `OP_PATH` 
to make sure that point to your operator manifests
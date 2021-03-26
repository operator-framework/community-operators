# Where to contribute

There are 2 directories where you can contribute, depending on some basic requirements and where you would like your Operator to show up:

| Target Directory               | Appears on                 | Target Platform             | Requirements                             |
|--------------------------------|----------------------------|-----------------------------|------------------------------------------|
| `community-operators`          | Embedded OperatorHub in OpenShift 4 | OpenShift / OKD             | needs to work on OpenShift 4 or newer    |
| `upstream-community-operators` | OperatorHub.io             | Upstream Kubernetes | needs to work on Kubernetes 1.7 or newer |

These repositories are used by OpenShift 4 and OperatorHub.io respectively. Specifically, Operators for Upstream Kubernetes for OperatorHub.io won't automatically appear on the embedded OperatorHub in OpenShift and should not be used on OpenShift.

**If your Operator works on both Kubernetes and OpenShift, place a copy of your packaged bundle in the `upstream-community-operators` directory, as well as the `community-operators` directory. Submit them as separate PRs.**

For partners and ISVs, certified operators can now be submitted via connect.redhat.com. If you have submitted your Operator there already, please ensure your submission here uses a different package name (refer to the README for more details).

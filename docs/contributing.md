# Submitting your Operator

!!! important "First off, thanks for taking the time to contribute your Operator!"

## A primer to Kubernetes Community Operators

This project collects Operators and publishes them to OperatorHub.io, a central registry for community-powered Kubernetes Operators. For OperatorHub.io your Operator needs to work with vanilla Kubernetes.
This project also collects Community Operators that work with OpenShift to be displayed in the embedded OperatorHub. If you are new to Operators, start [here](https://github.com/operator-framework/getting-started).

## Sign Your Work

The contribution process works off standard git _Pull Requests_. Every PR needs to be signed. The sign-off is a simple line at the end of the explanation for a commit. Your signature certifies that you wrote the patch or otherwise have the right to contribute the material. The rules are pretty simple, if you can certify the below (from [developercertificate.org](https://developercertificate.org/)):

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
1 Letterman Drive
Suite D4700
San Francisco, CA, 94129

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

Then you just add a line to every git commit message:

    Signed-off-by: John Doe <john.doe@example.com>

Use your real name (sorry, no pseudonyms or anonymous contributions.)

If you set your `user.name` and `user.email` git configs, you can sign your commit automatically with `git commit -s`.

Note: If your git config information is set properly then viewing the `git log` information for your commit will look something like this:

```
Author: John Doe <john.doe@example.com>
Date:   Mon Oct 21 12:23:17 2019 -0800

    Update README

    Signed-off-by: John Doe <john.doe@example.com>
```

Notice the `Author` and `Signed-off-by` lines **must match**.

## Package your Operator

This repository makes use of the [Operator Framework](https://github.com/operator-framework) and its packaging concept for Operators. Your contribution is welcome in the form of a _Pull Request_ with your Operator packaged for use with [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager/).

### Packaging format

Your Operator submission can be formatted either following the `packagemanifest` or the newer `bundle` format. The former allows to ship your entire Operator with all its versions in one single directory. The latter allows shipping individual releases in container images. Both are supported but mixing of formats within a single Operator is not allowed. You need to decide for one or the other for your entire Operator listing.

In general a released version of your Operator is described in a `ClusterServiceVersion` manifest alongside the `CustomResourceDefinitions` of your Operator and additional metadata describing your Operator listing.

#### Create a ClusterServiceVersion

To add your operator to any of the supported platforms, you will need to submit metadata for your Operator to be used by the [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager/) (OLM). This is YAML file called `ClusterServiceVersion` which contains references to all of the CRDs, RBAC rules, `Deployment` and container image needed to install and securely run your Operator. It also contains user-visible info like a description of its features and supported Kubernetes versions. Note that your Operator's CRDs are shipped in separate manifests alongside the CSV so OLM can register them during installation (your Operator is not supposed to self-register its CRDs).

[Follow this guide to create an OLM-compatible CSV for your operator](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/building-your-csv.md). You can also see an example [here](./required-fields.md#example-csv). An Operator's CSV must contain the fields mentioned [here](./required-fields.md#required-fields-for-operatorhub) for it to be displayed properly within the various platforms.

There is one CSV per version of your Operator alongside the CRDs.

#### Create a release using the `packagemanifest` format

The `packagemanifest` format is a directory structure in which the top-level directory represents your Operator as a `package`. Below that top-level directory are versioned sub-directories, one for each a released version of your Operator. The sub-directory names follow [semantic version](https://semver.org) of your Operator and contain the `CustomResourceDefinition`s and `ClusterServiceVersion`.

The exact version is the one of your Operator as defined in `spec.version` inside the CSV. The version should also be reflected in the CSV file name for ease of use. It is required that the `spec.name` field in the CSV is also the same as the package name. Follow the example below, assuming your Operator package is called `my-operator`:

```sh
$ tree my-operator/
my-operator
├── 0.1.0
│   ├── my-operator-crd1.crd.yaml
│   ├── my-operator-crd2.crd.yaml
│   └── my-operator.v0.1.0.clusterserviceversion.yaml
├── 0.5.0
│   ├── my-operator-crd1.crd.yaml
│   ├── my-operator-crd2.crd.yaml
│   ├── my-operator-crd3.crd.yaml
│   └── my-operator.v0.5.0.clusterserviceversion.yaml
├── 1.0.0
│   ├── my-operator-crd1.crd.yaml
│   ├── my-operator-crd2.crd.yaml
│   ├── my-operator-crd3.crd.yaml
│   └── my-operator.v1.0.0.clusterserviceversion.yaml
└── my-operator.package.yaml
```
The `package.yaml` is a YAML file at the root level of the package directory. It provides the package name, a selection of channels pointing to potentially different Operator Versions/CSVs and a default channel. The package name is what users on cluster see when they discover Operators available to install. Use channels to allow your users to select a different update cadence, e.g. `stable` vs. `nightly`. If you have only a single channel the use of `defaultChannel` is optional.

An example of `my-operator.package.yaml`:

```yaml
packageName: my-operator
channels:
- name: stable
  currentCSV: my-operator.v1.0.0
- name: nightly
  currentCSV: my-operator.v1.0.3-beta
defaultChannel: stable
```

Your CSV versioning should follow [semantic versioning](https://semver.org/) concepts. Again, `packageName`, the suffix of the `package.yaml` file name and the field in `spec.name` in the CSV should all refer to the same Operator name.

#### Create a release using the `bundle` format

Alternatively you can use the `bundle` format, which is nowadays also the default of the Operator-SDK. The `bundle` format has a top-level directory named after your Operator name in the `ClusterServiceVersion` directory. Inside are sub-directories for the individual bundle, named after the [semantic versioning](https://semver.org) release of your Operator.

Unlike the `packagemanifest` format all metadata is defined within the individual release of the Operator. That is, inside each bundle. This includes the channel definitions. Rather than describing the list of available release channels in a top-level `package.yaml` it is compiled dynamically when a bundle is added. The default channel is also defined within the bundle and overwritten by every new bundle you add (this is a known limitation and is being worked on).

Within each version you have your `CustomResourceDefinitions`, `ClusterServiceVersion` file (containing the same name and version of your Operator as defined inside the YAML structure) and some metadata about the bundle. You can [learn more about the bundle format here](https://github.com/operator-framework/operator-registry/blob/master/docs/design/operator-bundle.md) and also see some [examples](https://github.com/operator-framework/operator-registry/tree/master/bundles).

Your directory structure might look like this when using the `bundle` format. Notice that the `Dockerfile` is optionally and actually ignored. The processing pipeline of this site builds a container image for each of your bundle regardless.

```console
$ tree my-operator/

my-operator/
├── 0.1.0
│   ├── manifests
│   │   ├── my-operator-crd1.crd.yaml
│   │   ├── my-operator-crd2.crd.yaml
│   │   ├── my-operator-crd3.crd.yaml
│   │   └── my-operator.v0.1.0.clusterserviceversion.yaml
│   ├── metadata
│   │   └── annotations.yaml
│   └── Dockerfile
├── 0.5.0
│   ├── manifests
│   │   ├── my-operator-crd1.crd.yaml
│   │   ├── my-operator-crd2.crd.yaml
│   │   ├── my-operator-crd3.crd.yaml
│   │   └── my-operator.v0.5.0.clusterserviceversion.yaml
│   ├── metadata
│   │   └── annotations.yaml
│   └── Dockerfile
├── 1.0.0
│   ├── manifests
│   │   ├── my-operator-crd1.crd.yaml
│   │   ├── my-operator-crd2.crd.yaml
│   │   ├── my-operator-crd3.crd.yaml
│   │   └── my-operator.v1.0.0.clusterserviceversion.yaml
│   ├── metadata
│   │   └── annotations.yaml
│   └── Dockerfile
└── 2.0.0
    ├── manifests
    │   ├── my-operator-crd1.crd.yaml
    │   ├── my-operator-crd2.crd.yaml
    │   ├── my-operator-crd3.crd.yaml
    │   └── my-operator.v2.0.0.clusterserviceversion.yaml
    ├── metadata
    │   └── annotations.yaml
    └── Dockerfile
...
```
If you used `operator-sdk` to develop your Operator you can also leverage its packaging tooling to [create a bundle](https://sdk.operatorframework.io/docs/olm-integration/quickstart-bundle/#creating-a-bundle).

#### Moving from `packagemanifest` to `bundle` format

Eventually this repository will only accept bundle format at some point in the future. Also the `bundle` format has more features like `semver` mode or, in the future, installing bundles directly outside of a catalog.

Migration of existing content, irregardless of whether the Operator was created with the SDK, can be achieved with the `opm` tool on per Operator version basis. You can download `opm` [here](https://github.com/operator-framework/operator-registry/releases/latest).

Suppose `v2.0.0` is the version of the Operator you want to test convert to bundle format directory with the `opm` tool:

```console
mkdir /tmp/my-operator-2.0.0-bundle/
cd /tmp/my-operator-2.0.0-bundle/
opm alpha bundle build --directory /path/to/my-operator/2.0.0-bundle/ --tag my-operator-bundle:v2.0.0 --output-dir .
```

This will have generated the bundle format layout in the current working directory `/tmp/my-operator-2.0.0-bundle/`:

```console
$ tree .

/tmp/my-operator-2.0.0-bundle/
├── manifests
│   ├── my-operator-crd1.crd.yaml
│   ├── my-operator-crd2.crd.yaml
│   ├── my-operator-crd3.crd.yaml
│   └── my-operator.v2.0.0.clusterserviceversion.yaml
├── metadata
│   └── annotations.yaml
└── bundle.Dockerfile
```

You can verify the generated bundle metadata for semantic correctness with the the `operator-sdk` on this directory.

```console
operator-sdk bundle validate /tmp/my-operator-2.0.0-bundle/ --select-optional name=operatorhub
```

You can download `operator-sdk` [here](https://github.com/operator-framework/operator-sdk/releases/latest).

### Updating your existing Operator

Unless of purely cosmectic nature, subsequent updates to your Operator should result in new `bundle` directories being added, containing an updated CSV as well as copied, updated and/or potentially newly added CRDs. Within your new CSV, update the `spec.version` field to the desired new semantic version of your Operator.

In order to have OLM enable updates to your new Operator version you can choose between three update modes: `semver-mode`, `semver-skippatch-mode` and `replaces-mode`. The default is `semver-mode`. If you want to change the default, place a file called `ci.yaml` in your top-level directory (works for both `packagemanifest` or `bundle` format) and set it to either of the two other values. For example:

```yaml
updateGraph: replaces-mode
```

#### semver-mode
OLM treats all your Operator versions with semantic version rules and update them in order of those versions. That is, every version will be replaced by the next higher version according semantic versioning sort order. During an update on the cluster OLM will update all the way to the latest version, one version at a time. To use this, simply specify `spec.version` in your CSV. If you accidentally add `spec.replaces` this will contradict semantic versioning and raise an error.

#### semver-skippatch
Works like `semver` with a slightly different behavior of OLM on cluster, where instead of updating from e.g. `1.1.0` and an update path according to semver ordering rules like so: `1.1.0 -> 1.1.1 -> 1.1.2`, the update would jump straight to `1.1.2` instead of updating to `1.1.1` first.

#### replaces-mode
Each Operator bundle not only contains `spec.version` but also points to an older version it can upgrade from via `spec.replaces` key in the CSV file, e.g. `replaces: my-operator.v1.0.0`. From this chain of back pointers OLM computes the update graph at runtime. This allows to omit some versions from the update graph or release special leaf versions.

Regardless of which mode you choose to have OLM create update paths for your Operator, it continuous update your Operator often as new features are added and bugs are fixed.

### Operator Bundle Editor
You can now create your Operator bundle using the [bundle editor](https://operatorhub.io/packages). Starting by uploading your Kubernetes YAML manifests, the forms on the page will be populated with all valid information and used to create the new Operator bundle. You can modify or add properties through these forms as well. The result will be a downloadable ZIP file.

## Provide information about your Operator

A large part of the information gathered in the CSV is used for user-friendly visualization on [OperatorHub.io](https://operatorhub.io) or components like the embedded OperatorHub in OpenShift. Your work is on display, so please ensure to provide relevant information in your Operator's description, specifically covering:

* What the managed application is about and where to find more information
* The features your Operator and how to use it
* Any manual steps required to fulfill pre-requisites for running / installing your Operator

## Test locally before you contribute

The team behind OperatorHub.io will support you in making sure your Operator works and is packaged correctly. You can accelerate your submission greatly by testing your Operator with the Operator Framework by following our [documentation for local manual testing](./testing-operators.md) or automated testing [using scripts](./using-current-test-suite.md). You are responsible for testing your Operator's APIs when deployed with OLM.

## Verify CI test results

Every PR against this repository is tested via [Continuous Integration](./ci.md). During these tests your Operator will be deployed on either a `minikube` or OpenShift 4 environments and checked for a healthy deployment. Also several tools are run to check your bundle for completeness. These are the same tools as referenced in our [testing docs](./testing-operators.md) and [testing scripts](./using-current-test-suite.md). Pay attention to the result of GitHub checks.

## Where to contribute

There are 2 directories where you can contribute, depending on some basic requirements and where you would like your Operator to show up:

| Target Directory               | Appears on                 | Target Platform             | Requirements                             |
|--------------------------------|----------------------------|-----------------------------|------------------------------------------|
| `community-operators`          | Embedded OperatorHub in OpenShift 4 | OpenShift / OKD             | needs to work on OpenShift 4 or newer    |
| `upstream-community-operators` | OperatorHub.io             | Upstream Kubernetes | needs to work on Kubernetes 1.7 or newer |

These repositories are used by OpenShift 4 and OperatorHub.io respectively. Specifically, Operators for Upstream Kubernetes for OperatorHub.io won't automatically appear on the embedded OperatorHub in OpenShift and should not be used on OpenShift.

**If your Operator works on both Kubernetes and OpenShift, place a copy of your packaged bundle in the `upstream-community-operators` directory, as well as the `community-operators` directory. Submit them as separate PRs.**

For partners and ISVs, certified operators can now be submitted via connect.redhat.com. If you have submitted your Operator there already, please ensure your submission here uses a different package name (refer to the README for more details).

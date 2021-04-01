# Updating existing Operators

## Updating operator version

!!! note
    It is strongly recommended to bump operator version if possible.

Operator version update can be done by creating new directory with `version` name in operator dir without '`v`'. For example updating aqua operator from `1.0.0` to `1.0.1`

```
$ tree community-operators/aqua/ -d
community-operators/aqua/
├── 0.0.1
├── 0.0.2
├── 1.0.0
├── 1.0.1
```



## Minor (cosmetics) changes

There are some case when only some minor changes to the existing operator are needed (like description update or an update of icon). In this case pipeline will set coresponding label and automatically handle such case.

### Allowed changes

- Only changes in csv (*.clusterserviceversion.yaml) are allowed
- List of allowed tag changes in csv
    - `spec.description`
    - `spec.DisplayName`
    - `spec.icon`

## Operator versioning strategy 

!!! warning
    Updating existing `ci.yaml` is `only` possible via an extra PR with single file modification. Otherwise tests will fail

Sometimes it is needed to change how operator versions are built in to the index. This can be controlled by `ci.yaml` file. [More info](./operator-ci-yaml.md#reviewers)

## Reviewers update

!!! warning
    Updating existing `ci.yaml` is `only` possible via an extra PR with single file modification. Otherwise tests will fail

While operator is involving over a time, some time it is needed to change reviewers. This can be controlled by `ci.yaml` file. [More info](./operator-ci-yaml.md#operator-versioning)






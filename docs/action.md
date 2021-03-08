# Community operator action V1

This action runs community operator tests.

# What's new

- Supported tests (kiwi,lemon,orange)
- Own [community-operators](https://github.com/operator-framework/community-operators.git) fork and branch supported
- Run test from own repository. Doesn't have to be [community-operators](https://github.com/operator-framework/community-operators.git). More info in [op-action-examples](https://github.com/mvalarh/op-action-examples)


# Usage

<!-- start usage -->
```yaml

- uses: operator-framework/community-operators@v1
  with:
    # Test type (kiwi,lemon or orange)
    test-type: 'kiwi'
    
    # Operator stream name (community-operators or upstream-community-operators)
    stream: 'community-operators'
    
    # Operator name (exmaple 'aqua')
    name: ''
    
    # Operator version (exmaple '5.3.0')
    version: ''
    
    # Community operators repo
    # Default: 'https://github.com/operator-framework/community-operators.git'
    repo: ''

    # Community operators branch
    # Default: 'master'
    branch: ''

    # Repo directory when if not community-operators
    # Default: 'community-operators'
    repo-dir: ''

    # Space separated list of labels in PR
    # Default: ''
    pr-labels: ''

    # Path to operator version content (for example local/path/to/operator/version).
    # Default: ''
    operator-version-path: ''

    # Path to package file (for example local/path/to/my-operator.package.yaml).
    # Default: ''
    package-path: ''

    # Path to ci.yaml file (for example local/path/to/ci.yaml).
    # Default: ''
    ci-path: ''
```
<!-- end usage -->

## Test 'kiwi' aqua operator version 5.3.0 for in community-operators

```yaml

- uses:  operator-framework/community-operators@v1
  with:
    test-type: 'kiwi'
    stream: 'upstream-community-operators'
    name: 'aqua'
    version: '5.3.0'
```

## Test 'kiwi' aqua operator version 5.3.0 for in upstream-community-operators

```yaml

- uses:  operator-framework/community-operators@v1
  with:
    test-type: 'kiwi'
    stream: 'upstream-community-operators'
    name: 'aqua'
    version: '5.3.0'
```

## Test 'lemon' aqua operator version 5.3.0 for in upstream-community-operators

```yaml

- uses:  operator-framework/community-operators@v1
  with:
    test-type: 'lemon'
    stream: 'upstream-community-operators'
    name: 'aqua'
    version: '5.3.0'
```

## Test 'orange' (catalog v4.6) for aqua operator version 5.3.0 for in community-operators

```yaml

- uses:  operator-framework/community-operators@v1
  with:
    test-type: 'oragne_v4.6'
    stream: 'community-operators'
    name: 'aqua'
    version: '5.3.0'
```


## Test 'kiwi' aqua operator version 5.3.0 for in upstream-community-operators in own project
Test single version of operator from custom project. Follwoing will happen:

- Action will clone `https://github.com/operator-framework/community-operators.git` in to master branch (controlled by `repo:` and `branch:`)
- Enters directory `community-operators` (controlled by `repo-dir:`)
- Removes directory `upstream-community-operators/aqua/5.3.0`
- Creates directory `upstream-community-operators/aqua/5.3.0`
- Copy content `my/op/manifest` to `upstream-community-operators/aqua/5.3.0` (controlled by `operator-version-path:`)
- Copy/overwrite `my/op/aqua-operator.package.yaml` to `upstream-community-operators/aqua/` (controlled by `package-path:`)
- Copy/overwrite `my/op/ci.yaml` to `upstream-community-operators/aqua/` (controlled by `ci-path:`)
- Runs `kiwi` test (controlled by `test-type:`)

```yaml
- uses:  operator-framework/community-operators@v1
  with:
    test-type: 'kiwi'
    stream: 'upstream-community-operators'
    name: 'aqua'
    version: '5.3.0'
    repo: 'https://github.com/operator-framework/community-operators.git'
    branch: 'master'
    operator-version-path: my/op/manifest
    package-path: my/op/aqua-operator.package.yaml
    ci-path: my/op/ci.yaml
```

# License

The scripts and documentation in this project are released under the [MIT License](LICENSE)



# Operator Updates

Please take a look at the [upstream OLM documentation](https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-registry/building-a-catalog/)

## Add Modes

Here you'll find suggested update graphs for different add modes with an explanation of impact and caveats for each one.

### Replaces Mode

#### One channel across / per OCP version

Each channel always only ever has a single version. Every new release overwrites that channel head. Any past version can update to it because of `skipRange`. This is common for teams with regular / automated release / continuous productization (ex: optional operators in openshift).

4.5 Index

```
stable:
    myoperator.4.5.timestamp [olm.skipRange <= 4.5]
```

4.6 Index

```
stable:
    myoperator.4.6.timestamp [olm.skipRange <= 4.6] (includes all 4.5 versions)
```

4.7 Index

```
stable:
    myoperator.4.7.timestamp [olm.skipRange <= 4.7] (includes all 4.5 and 4.6 versions)
```

##### Impact

- [x] all updates possible across indexes
- [ ] (NA) all updates possible across channels
- [x] can release CVE fixes / z-stream updates for all major / minor versions
- [x] all updates are fast-tracked to the head of the channel
- [ ] cannot install past versions
- [x] marking versions as uninstallable is not needed because of fast-tracking to the head of the channel

#### One channel per z-stream

Each index has a set of z-streams the team is interested in supporting. These minor releases are not necessarily tied to OCP GA dates and are usually tied to the operand version whose support statement is tied to OCP EOL dates. Typically teams have multiple operand versions they support at a time.

4.5 Index

```
release-1.0:
    1.0.0 -> 1.0.1 -> 1.0.2
```

4.6 Index

```
release-1.0:
    1.0.0 -> 1.0.1 -> 1.0.2
release-1.1:
    1.1.0 -> 1.1.1
```

4.7 Index

```
release-1.0:
    1.0.0 -> 1.0.1 -> 1.0.2
release-1.1:
    1.1.0 -> 1.1.1
release-1.2:
    1.2.0
```

##### Impact

- [x] all updates possible across indexes
- [ ] updates possible across channels
    - only possible if using skipRange
- [x] can release CVE patches for all minor versions
    - seems acceptable to ask folks to update to 1.0.2 instead of releasing a 1.0.1-fixed version
- [x] updates can be fast-tracked by using skips
- [x] can install past versions
- [x] can mark versions as uninstallable using skips or by deprecating

#### One z-stream per OCP version

Each index has a z-stream the team is interested in supporting. These minor releases are tied to OCP GA dates.

4.5 Index
```
fast:
    1.0.0 -> 1.0.1 -> 1.0.2
stable:
    1.0.0 -> 1.0.1
```
4.6 Index
```
fast:
    1.1.0 -> 1.1.1
stable:
    1.1.0
```
4.7 Index
```
fast:
    1.2.0 -> 1.2.1
stable:
    1.2.0
```

##### Impact

- [ ] updates possible across indexes
    - only possible if using skipRange or maintaining a list of skips
- [ ] updates possible across channels
    - only possible if using skipRange or maintaining a list of skips
- [x] can release CVE patches for all minor versions
    - seems acceptable to ask folks to update to 1.0.2 instead of releasing a 1.0.1-fixed version
- [x] updates can be fast-tracked by using skips
- [ ] can install some past versions
    - versions from the previous index cannot be installed
- [x] can mark versions as uninstallable using skips or by deprecating

#### Continuously moving forward

This is popular with teams that don't have multiple operand versions supported at a given time or teams that have given specific install instructions to their customers to pin specific past versions in a given channel.

4.5 Index
```
fast:
    1.0.0 -> 1.0.1 -> 1.0.2 -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1 -> 1.2.2
stable:
    1.0.0 -> 1.0.1 -> 1.0.2 -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1
```

4.6 Index
```
fast:
    1.0.2 [dep] -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1 -> 1.2.2
stable:
    1.0.2 [dep] -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1
```
4.7 Index

```
fast:
    1.1.1 [dep] -> 1.2.0 -> 1.2.1 -> 1.2.2
stable:
    1.1.1 [dep] -> 1.2.0 -> 1.2.1
```

Note that although this graph looks like a promotion mechanism exists to promote a version from fast to stable, this is not the case today. Versions in the replacement chain appear as a result of publishing a new release to a given channel. In the example above, publishing 1.2.3 to the stable channel would result in 1.2.2 also being added to the stable channel.

##### Impact

- [x] all supported updates possible across indexes
- [x] updates possible across channels
    - from stable to fast
- [ ] can only release CVE patches for channel heads
    - releasing 1.0.3 to patch 1.0.2 is not possible
- [x] updates can be fast-tracked by using skips
- [x] can install past versions
- [x] can mark versions as uninstallable using skips or by deprecating

### Pros of Replaces Mode

1. Can specify updates between versions by csv name (could have 1.0.0 replaces 1.0.1)
2. Can fast-track updates by using skips
3. Can modify how past releases fit in the update graph by using skips

### Cons of Replaces Mode

1. Supporting multiple z-streams in a given index can only be done by having channels per minor version (as in example 2)
2. Cross-channel updates need to be explicitly defined
3. Can modify how past releases fit in the update graph by using skips
4. Relation between operator and operand version is unclear
5. New additions are assumed to be the latest (from opm perspective) - if there is no relation between new additions and past releases these past releases can be wiped out of the index. (example: using skipRange to define the next node instead of replaces)

### Semver Mode

Examples 1-4 above are all possible in semver mode with added benefits:

- Example 2 in semver does not require special skipRange to allow for cross-channel updates.
- Example 4 in semver can release CVE patches to any minor version (see example 5)

#### Continuous z-stream

This is helpful for teams wanting to support multiple z-streams without having to worry about cross-channel updates.

4.5 Index
```
fast:
    1.0.0 -> 1.0.1 -> 1.0.2 -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1 -> 1.2.2
stable:
    1.0.0 -> 1.0.1 -> 1.0.2 -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1
```

4.6 Index
```
fast:
    1.0.2 [dep] -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1 -> 1.2.2
stable:
    1.0.2 [dep] -> 1.1.0 -> 1.1.1 -> 1.2.0 -> 1.2.1
```

4.7 Index
```
fast:
    1.1.1 [dep] -> 1.2.0 -> 1.2.1 -> 1.2.2
stable:
    1.1.1 [dep] -> 1.2.0 -> 1.2.1
```

##### Impact

- [ ] all supported updates possible across indexes
    - only possible if using skipRange (versions need to be in the index in order to get updates)
- [x] updates possible across channels
    - from stable to fast
- [ ] can release CVE patches for all minor versions
    - seems acceptable to ask folks to update to 1.0.2 instead of releasing a 1.0.1-fixed version
- [ ] updates cannot be fast-tracked - must step through all versions
- [x] can install past versions
- [ ] can mark versions as uninstallable by deprecating (once deprecation is available in semver).
    - Might prefer to mark minor versions as deprecated instead of specific versions
    - Can also decide not to pull versions forward because semver mode does not require implicit replacement to be present in the index for addition to succeed. (**GAP**) There is no way today for a team to declare they don't want versions pulled forward.

### Semver Skippatch Mode

Examples 1-4 above are all possible in semver skippatch mode with added benefits:

- Example 4 will always skip to the latest z-stream of a given minor version (i.e. 1.0.0 -> 1.0.3 in one hop instead of going through each incremental update)
    - updating to CVE patched versions can be done without stepping through CVE affected versions
    - updates are fast-tracked for z-streams
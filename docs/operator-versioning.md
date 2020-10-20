## Operator versioning

Operators have multiple versions. When a new version is released, OLM can update operator automatically. There are 2 update strategies possible, which are defined in `ci.yaml` at the operator top level.

#### replaces-mode
Every next version defines which version will be replaced using `replaces` key in the CSV file. It means, that there is a possibility to omit some versions from the update graph. Best practice is to put them to a separate channel then.

#### semver-mode
Every version will be replaced by next higher version according semantic versioning.

### Restrictions
Contributor can decide, if `semver-mode` or `replaces-mode` mode will be used for a specific operator. By default, `replaces-mode` is activated, when `ci.yaml` file is present and contains `updateGraph: replaces-mode`. When a contributor decides to switch and use `semver-mode`, it will be specified in `ci.yaml` file or the file will be missing.
Once swithed to `semver-mode`, there is no easy way to switch back. It is possible, that `replaces-mode` will be depracated in the future.
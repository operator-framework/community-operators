# Publish Operator updates self-sufficiently

Updating a published Operator is done by merging PR in to the main branch [community-operators](https://github.com/operator-framework/community-operators/pulls).

By default only [community-operators](https://github.com/operator-framework/community-operators) maintainers can merge PRs to main branch. They will do so if all validation and deployment tests done as part of the automatic checks running on every PR are successful.

If you want to speed up the process of publishing an update, it is possible to have your PRs automatically merge without reviews by the maintainers. The following criteria needs to be met:

- All GitHub checks are succesful
- If you are updating an already published Operator, only minor (cosmetic) changes are done ([more info](./operator-version-strategy))
- You are part of the `reviewer` group for the Operator in question ([more info](./operator-ci-yaml.md#reviewers))

If those criteria are fulfilled a label called `authorized_changes` will be set on the PR which causes the PR to be automatically merged.

# How do I set up reviewers?

Learn more [here](./operator-ci-yaml.md#reviewers). Remember that modifications to `ci.yaml` need to be reviewed by current reviewers or the maintainers (if no reviewers exist).

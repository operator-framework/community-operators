# Automatic deployment of a operator

Deployment of a operator is done by merging PR in to the main branch [community-operators](https://github.com/operator-framework/community-operators/pulls).

!!! note
    Currently only [community-operators](https://github.com/operator-framework/community-operators) maintainers can merge PRs to main branch. Automatic merging will be supported soon. 

Operator will be merged automatically (currently done by maintainers), when number of criteria will be fullfill:

- All tests are green
- PR is reviewed by all reviewers

# How do I merge faster?

One can follow these best practicies:

- Bump operator version if posible.
- Setup reviewer and review it by your team. [More info](./operator-ci-yaml.md#reviewers)
- Do only minor (cosmetic) changes to existing operator. [More info](./operator-version-strategy)
- Remember that modifications to `ci.yaml` can be done only with a PR with single file change modification.
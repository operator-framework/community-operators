# Troubleshooting

## PR-traffic-light failures:

!!! error "Operator changes detected with ci changes and 'allow/ci-changes' is not set"
    Do not modify files outside of community-operators and upstream-community-operators, please rebase or fix and push changes.

!!! error "Changes in both 'community-operators' and 'upstream-community-operators' dirs"
    Every operator must have separate PR. Separate for Kubernetes (upstream) and separate for Openshift (community). It helps more precise testing and also granular revert if needed. Sometimes just rebase is needed.

!!! error "Multiple operators are changed"
    Multiple operators in the same stream are updated. This is not allowed. It could be a result of not rebased PR. Please rebase or create separate PR for every operator.

!!! error "We support only a single file modification in case of 'ci.yaml' file. If you want to update it, please make an extra PR with 'ci.yaml' file modification only!!!"
    Please make an extra PR and modify only `ci.yaml`. 

## Package metadata test (kiwi) test failures:

!!! error "Operator deployment with OLM failed"
    Could be multiple reasons, but first of all, please check if your operator image can be pulled from a public location. This is the most common root cause for operators failing to start. Tests for this situation are planned in backlog, so pipeline will tell you this in near future automatically.

!!! error "csv.Spec.Icon not specified"
    Icon is mandatory, more information [here](https://github.com/operator-framework/community-operators/blob/master/docs/contributing.md#operator-icon).

## ci/prow/deploy-operator-on-openshift failures:

!!! error "Test Failed?"
    To investigate every failed Openshift test, please open test `Details` and click `Show all hidden lines`. Then scroll to the bottom and check all logs from bottom to top. Logs are ordered according to debugging value, the most important logs are at the bottom, least important and some initialization staff is at the top of every run.

!!! error "Temp index not found. Are your commits squashed?"
    Error message combined with `Missing '$OP_NAME'` or similar. Majority of tests ending without a temporary index are caused by PR containing too many commits. Please (rebase) squash and force-push. If it is not your case, you can inspect logs from building temporary indexes for test purposes here https://github.com/operator-framework/community-operators/actions?query=workflow%3Aprepare-test-index.

!!! error "Operation cannot be fulfilled on ... the object has been modified; please apply your changes to the latest version and try again"
    This is not an issue, you can ignore it.

!!! error "ImagePullBackOff error message"
    Unable to pull your operator image.

## Operator deploy tests (lemon/oragne) test failures:

!!! error "All operator versions are already in catalog"
    You are trying to edit an existing operator version. It is not recommended. But there are some exceptions, where you just edit some description or link. In this case, repository maintainers can set appropriate labels to override such errors and approve release pipeline action to overwrite an existing operator.
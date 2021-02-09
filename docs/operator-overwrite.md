# Orange test fails even when my operator is ok. 
There is one case when your operator is correct, but orange test might failt. This happened when some operator versions are already published and one wants to change
some cosmetic changes to bundle or convert format from `package manifest` to `bundle` format. In tese scenarios one can follow instruction bellow

- Operator version overwrite
- Operator recreate

## Operator version overwrite
When cosmetic changes are made to already published operator version `Orange` test will fail. In this case one needs to have `allow/operator-version-overwrite` label set. One can set it or ask maintainer to set it for you.

After the PR will be merged, the following changes will happen

- Bundle for current operator version will be overwritten
- Build catalog with new bundle

## Operator recreate
When a whole operator is recreated (usually when converting whole operator from packagemanifest format to bundle format). One needs to have `allow/operator-recreate` label set. One can set it or ask maintainer to set it for you.

After the PR will be merged, the following changes will happen

- Delete operator
- Rebuild all bundles
- Build catalog with new bundles

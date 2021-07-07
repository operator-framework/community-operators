#!/bin/bash
# OPerator Pipeline (OPP) env script (opp-env.sh)

set -e
export INPUT_ENV_SCRIPT="/tmp/opp-env-vars"
OPP_ALLOW_CI_CHANGES=${OPP_ALLOW_CI_CHANGES-0}
OPP_TEST_READY=${OPP_TEST_READY-1}
OP_RELEASE_READY=${OP_RELEASE_READY-0}
OPP_OP_DELETE=${OPP_OP_DELETE-0}
OPP_PR_AUTHOR=${OPP_PR_AUTHOR-""}
DELETE_APPREG=${DELETE_APPREG-0}
OPRT=${OPRT-0}
OPP_CURRENT_PROJECT_REPO=${OPP_CURRENT_PROJECT_REPO-"operator-framework/community-operators"}
OPP_CURRENT_PROJECT_BRANCH=${OPP_CURRENT_PROJECT_BRANCH-"master"}
OPP_CURRENT_PROJECT_DOC=${OPP_CURRENT_PROJECT_DOC-"https://operator-framework.github.io/community-operators"}

OPP_PRODUCTION_TYPE=${OPP_PRODUCTION_TYPE-"ocp"}
OPP_OPERATORS_DIR=${OPP_OPERATORS_DIR-"operators"}

OPP_CHANGES_GITHUB=0
OPP_CHANGES_CI=0
OPP_CHANGES_DOCS=0
OPP_CHANGES_IN_OPERATORS_DIR=0
OPP_CHANGES_STREAM_UPSTREAM=0
OPP_CI_YAML_CHANGED=0
OPP_CI_YAML_ONLY=0
OPP_CI_YAML_MODIFIED=0
OPP_ALLOW_SERIOUS_CHANGES=0
OPP_IS_OPERATOR=0
OPP_IS_NEW_OPERATOR=0
OPP_PR_TITLE=
OPP_AUTHORIZED_CHANGES=0
OPP_REVIEVERS=""
OPP_CHANGES_DOCKERFILE=0

# Error codes:
#   [1] overwrite and recreate labels set at same time
#   [2] both streams set
#   [3] non opearator files changed in directories : .github, docs, ...
#   [4] ci.yaml
#   [5] multiple operator changed
#   [6] Old version were changed and recreate label is not set
#   [7] Single file modification for ci.yaml allowed only
#   [10] Inform users about possibility to add reviewers
OPP_ERROR_CODE=0

OPP_VER_OVERWRITE=${OPP_VER_OVERWRITE-0}
OPP_RECREATE=${OPP_RECREATE-0}

OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0
OPP_SET_LABEL_OPERATOR_RECREATE=0
OPP_IS_MODIFIED=0
OPP_MODIFIED_CSVS=
OPP_UPDATEGRAPH=1
OPP_CI_YAML_UNSUPPORTED_FIELDS="addAssignees useAssigneeGroups assigneeGroups skipKeywords"

echo "OPP_ADDED_MODIFIED_FILES=$OPP_ADDED_MODIFIED_FILES"
echo "OPP_MODIFIED_FILES=$OPP_MODIFIED_FILES"
echo "OPP_RENAMED_FILES=$OPP_RENAMED_FILES"
echo "OPP_REMOVED_FILES=$OPP_REMOVED_FILES"
echo "OPP_LABELS=$OPP_LABELS"

echo "::set-output name=opp_error_code::$OPP_ERROR_CODE"
echo "::set-output name=opp_recreate::${OPP_RECREATE}"


for l in $(echo $OPP_LABELS);do
  echo "Checking label '$l' ..."
  [[ "$l" = "allow/ci-changes" ]] && export OPP_ALLOW_CI_CHANGES=1
  [[ "$l" = "allow/operator-version-overwrite" ]] && export OPP_VER_OVERWRITE=1
  [[ "$l" = "allow/operator-recreate" ]] && export OPP_OP_DELETE=1 && export OPP_RECREATE=1
  [[ "$l" = "allow/serious-changes-to-existing" ]] && export OPP_ALLOW_SERIOUS_CHANGES=1
  
done
echo "::set-output name=opp_recreate::${OPP_RECREATE}"

[[ $OPP_VER_OVERWRITE -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && { echo "Labels 'allow/operator-version-overwrite' and 'allow/operator-recreate' is set. Only one label can be set !!! Exiting ..." ; echo "::set-output name=opp_error_code::1"; exit 1; }

OPP_CHANGES_OPERATOR=
OPP_CHANGES_OPERATOR_VERSIONS_MODIFIED=
OPP_CHANGES_OPERATOR_VERSIONS_REMOVED=


echo "::set-output name=opp_set_label_operator_version_overwrite::$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE"
echo "::set-output name=opp_set_label_operator_recreate::$OPP_SET_LABEL_OPERATOR_RECREATE"
echo "::set-output name=opp_is_modified::$OPP_IS_MODIFIED"
echo "::set-output name=opp_modified_csvs::$OPP_MODIFIED_CSVS"
echo "::set-output name=opp_allow_serious_changes::$OPP_ALLOW_SERIOUS_CHANGES"
echo "::set-output name=opp_is_new_operatror::${OPP_IS_NEW_OPERATOR}"
echo "::set-output name=opp_pr_title::${OPP_PR_TITLE}"
echo "::set-output name=opp_update_graph::${OPP_UPDATEGRAPH}"
echo "::set-output name=opp_authorized_changes::${OPP_AUTHORIZED_CHANGES}"

# Handle removed files
if [ -n "$OPP_REMOVED_FILES" ];then

  # Some files are removed
  # TODO : OPP_CHANGES_OPERATOR_VERSIONS_REMOVED
  FILES=
  for sf in ${OPP_REMOVED_FILES}; do
    echo $sf
    # Check if .github/ dir is modified
    [[ $sf == .github* ]] && OPP_CHANGES_GITHUB=1 && continue
    [[ $sf == scripts* ]] && OPP_CHANGES_CI=1 && continue
    [[ $sf == ci* ]] && OPP_CHANGES_CI=1 && continue
    [[ $sf == docs* ]] && OPP_CHANGES_DOCS=1 && continue
    [[ $sf == *Dockerfile* ]] && OPP_CHANGES_DOCKERFILE=1 && continue
    [[ $sf == operators* ]] && OPP_CHANGES_IN_OPERATORS_DIR=1
    # [[ $sf == community-operators* ]] && OPP_CHANGES_IN_OPERATORS_DIR=1
    # [[ $sf == upstream-community-operators* ]] && OPP_CHANGES_STREAM_UPSTREAM=1
    [[ $sf == *package.yaml ]] && continue
    [[ $sf == *ci.yaml ]] && { OPP_CI_YAML_CHANGED=1; continue; }
    # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 0 ]] && { echo "No changes 'community-operators' or 'upstream-community-operators' !!! Exiting ..."; OP_RELEASE_READY=0; }
    FILES="$FILES $(echo $sf | cut -d '/' -f 1-3)"
    # Check if outdside of "community-operators" and "upstream-community-operators"
  done

  [ -n "$FILES" ] && OPP_IS_OPERATOR=1

  # Handle removed only files
  if [ ! -n "$OPP_ADDED_MODIFIED_FILES" ];then
    # check if only ci.yaml was removed
    OP_RELEASE_READY=1


    # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && OPP_OPERATORS_DIR="community-operators"
    # [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && OPP_OPERATORS_DIR="upstream-community-operators"

    VERSIONS=$(echo -e "${FILES// /\\n}" | uniq | sort -r)
    LATEST="$(echo -e $VERSIONS | cut -d ' ' -f 1)"
    OPP_OPERATOR_NAME=$(echo $LATEST | cut -d '/' -f 2)
    OPP_OPERATOR_VERSION=$(echo $LATEST | cut -d '/' -f 3)

    OPP_TEST_READY=0

    # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && { echo "Changes in both 'community-operators' and 'upstream-community-operators' dirs !!! Exiting ..."; echo "::set-output name=opp_error_code::2"; exit 1; }

    echo "::set-output name=opp_test_ready::${OPP_TEST_READY}"
    echo "::set-output name=opp_release_ready::${OP_RELEASE_READY}"
    echo "::set-output name=opp_production_type::${OPP_PRODUCTION_TYPE}"
    echo "::set-output name=opp_name::${OPP_OPERATOR_NAME}"
    echo "::set-output name=opp_version::${OPP_OPERATOR_VERSION}"
    echo "::set-output name=opp_changed_ci_yaml::${OPP_CI_YAML_CHANGED}"
    echo "::set-output name=opp_ver_overwrite::${OPP_VER_OVERWRITE}"
    echo "::set-output name=opp_update_graph::${OPP_UPDATEGRAPH}"
    
    echo "Files removed only."
    if [ ! -d ${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME} ];then
      OPP_OP_DELETE=1
      DELETE_APPREG=1
      echo "opp_release_delete_appreg=${DELETE_APPREG}"
      echo "::set-output name=opp_release_delete_appreg::${DELETE_APPREG}"
      echo "opp_test_ready=${OPP_TEST_READY}"
      echo "opp_release_ready=${OP_RELEASE_READY}"
      echo "opp_op_delete=$OPP_OP_DELETE"
      echo "opp_ver_overwrite=$OPP_VER_OVERWRITE"
      echo "::set-output name=opp_op_delete::${OPP_OP_DELETE}"
      echo "::set-output name=opp_is_modified::$OPP_IS_MODIFIED"
      echo "Directory '${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME}' is removed. This is OK."

      exit 0
    else
      echo "Directory '${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME}' is NOT removed. Searching for remaining versions"
      for f in $(find ${OPP_OPERATORS_DIR}/${OPP_OPERATOR_NAME} -type f);do
        [[ $f == *ci.yaml ]] && continue
        OPP_ADDED_MODIFIED_FILES="$OPP_ADDED_MODIFIED_FILES $f"
        
      done
      echo "Final modified files are :"
      echo "$OPP_ADDED_MODIFIED_FILES"
      [ -n "$OPP_ADDED_MODIFIED_FILES" ] && OPP_TEST_READY=1
    fi

  else
    REMOVED_VERSIONS=$(echo -e "${FILES// /\\n}" | uniq | sort -r)
    FILES=
  fi
fi

# Only MODIFIED_FILES here
OPP_ADDED_MODIFIED_FILES="$OPP_ADDED_MODIFIED_FILES $OPP_RENAMED_FILES"

FILES=
for sf in ${OPP_ADDED_MODIFIED_FILES}; do
  echo "$sf"
  # Check if .github/ dir is modified
  [[ $sf == .github* ]] && OPP_CHANGES_GITHUB=1 && continue
  [[ $sf == scripts* ]] && OPP_CHANGES_CI=1 && continue
  [[ $sf == ci* ]] && OPP_CHANGES_CI=1 && continue
  [[ $sf == docs* ]] && OPP_CHANGES_DOCS=1 && continue
  [[ $sf == *Dockerfile* ]] && OPP_CHANGES_DOCKERFILE=1 && continue
  # [[ $sf == community-operators* ]] && OPP_CHANGES_IN_OPERATORS_DIR=1
  # [[ $sf == upstream-community-operators* ]] && OPP_CHANGES_STREAM_UPSTREAM=1

  [[ $sf == *package.yaml ]] && continue
  [[ $sf == *ci.yaml ]] && OPP_CI_YAML_CHANGED=1 && continue
  [[ $sf == *mkdocs.yml ]] && continue

  # [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 0 ]] && { echo "No changes 'community-operators' or 'upstream-community-operators' Skipping test ..."; OPP_TEST_READY=0; }

  OPERATOR_PATH=$(echo $sf | cut -d '/' -f 1-3)
  [ -f $OPERATOR_PATH ] && { echo "Operator path '$OPERATOR_PATH' is file and it should be directory !!!"; exit 1; }
  FILES="$FILES $OPERATOR_PATH"

  # Check if outdside of "community-operators" and "upstream-community-operators"
done

echo ""

for sf in ${OPP_MODIFIED_FILES}; do
  echo "modified only: $sf"
  
  [[ $sf == *package.yaml ]] && continue
  [[ $sf == *ci.yaml ]] && OPP_CI_YAML_MODIFIED=1 && continue
  [[ $sf == *Dockerfile* ]] && OPP_CHANGES_DOCKERFILE=1 && continue
  if [[ $sf == *.clusterserviceversion.yaml ]];then
    OPP_MODIFIED_CSVS="$sf $OPP_MODIFIED_CSVS"
  else
    OPP_MODIFIED_OTHERS="$sf $OPP_MODIFIED_OTHERS"
  fi
  OPP_IS_MODIFIED=1
done
echo "OPP_MODIFIED_CSVS=$OPP_MODIFIED_CSVS"
echo "OPP_MODIFIED_OTHERS=$OPP_MODIFIED_OTHERS"

# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 0 ]] && [[ $OPP_CI_YAML_CHANGED -eq 0 ]] && { echo "No changes 'community-operators' or 'upstream-community-operators' !!! Skipping test ..."; OPP_TEST_READY=0; }

# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && { echo "Changes in both 'community-operators' and 'upstream-community-operators' dirs !!! Exiting ..."; echo "::set-output name=opp_error_code::2"; exit 1; }

[[ $OPP_CHANGES_GITHUB -eq 1 ]] && [[ $OPP_ALLOW_CI_CHANGES -eq 0 ]] && { echo "Changes in '.github' dir, but 'allow/ci-changes' label is not set !!!"; echo "::set-output name=opp_error_code::3"; OPP_TEST_READY=0; exit 1; }
[[ $OPP_CHANGES_CI -eq 1 ]] && [[ $OPP_ALLOW_CI_CHANGES -eq 0 ]] && { echo "Changes in ci, but 'allow/ci-changes' label is not set !!!"; echo "::set-output name=opp_error_code::3"; OPP_TEST_READY=0; exit 1; }
[[ $OPP_CHANGES_DOCS -eq 1 ]] && [[ $OPP_ALLOW_CI_CHANGES -eq 0 ]] && { echo "Changes in docs, but 'allow/ci-changes' label is not set !!!"; echo "::set-output name=opp_error_code::3"; OPP_TEST_READY=0; exit 1; }
# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 || $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_TEST_READY -eq 0 ]] && { echo "Error: Operator changes detected with ci changes and 'allow/ci-changes' is not set !!! Exiting ..."; echo "::set-output name=opp_error_code::3";  exit 1; }
# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 && $OPP_CHANGES_IN_OPERATORS_DIR -eq 0 ]] && [[ $OPP_TEST_READY -eq 0 ]] && { echo "Nothing to test"; exit 0; }
[[ $OPP_TEST_READY -eq 0 ]] && { echo "Nothing to test"; exit 0; }

# [[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && OPP_OPERATORS_DIR="community-operators"
# [[ $OPP_CHANGES_STREAM_UPSTREAM -eq 1 ]] && OPP_OPERATORS_DIR="upstream-community-operators"

[[ $OPP_CHANGES_IN_OPERATORS_DIR -eq 1 ]] && [[ $OPP_CI_YAML_CHANGED -eq 1 ]] && [ ! -n "$FILES" ] && OPP_CI_YAML_ONLY=1 && FILES=${OPP_ADDED_MODIFIED_FILES}

echo "FILES: $FILES"

VERSIONS=$(echo -e "${FILES// /\\n}" | uniq | sort -r)

LATEST="$(echo -e $VERSIONS | cut -d ' ' -f 1)"
OPP_OPERATOR_NAME=$(echo $LATEST | cut -d '/' -f 2)
OPP_OPERATOR_VERSION=$(echo $LATEST | cut -d '/' -f 3)
OPP_OPERATOR_VERSIONS_ALL="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | cut -d '/' -f 3 | tr '\n' ' ')"
OPP_OPERATOR_VERSIONS_ALL_LATEST="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"

OPP_OPERATOR_VERSIONS=
for v in $VERSIONS;do
  TMP_OP_NAME=$(echo $v | cut -d '/' -f 2)
  OPP_OPERATOR_VERSIONS="$(echo $v| cut -d '/' -f 3) $OPP_OPERATOR_VERSIONS"
  [ "$OPP_OPERATOR_NAME" = "$TMP_OP_NAME" ] || { echo "Error: Multiple operators are changed !!! Detected:'$OPP_OPERATOR_NAME' and '$TMP_OP_NAME' !!! Exiting ..."; OPP_TEST_READY=0; echo "::set-output name=opp_error_code::5";  exit 1;  }
done
# remove trailing space
OPP_OPERATOR_VERSIONS=$(echo $OPP_OPERATOR_VERSIONS | sed 's/ *$//g')
OPP_OPERATOR_VERSIONS=$(echo $OPP_OPERATOR_VERSIONS | tr ' ' '\n' | uniq |  tr '\n' ' ' | sed 's/ *$//')

OPP_OPERATOR_VERSIONS_REMOVED=
for v in $REMOVED_VERSIONS;do
  OPP_OPERATOR_VERSIONS_REMOVED="$(echo $v| cut -d '/' -f 3) $OPP_OPERATOR_VERSIONS_REMOVED"  
done
# remove trailing space
OPP_OPERATOR_VERSIONS_REMOVED=$(echo $OPP_OPERATOR_VERSIONS_REMOVED | sed 's/ *$//g')

[[ $OPP_PROD -ge 1 ]] && OP_RELEASE_READY=1

if [[ $OPP_CI_YAML_ONLY -eq 1 ]];then
  if [[ $OPP_PROD -ge 1 ]];then
    OPP_OPERATOR_VERSION="sync"
    OPP_OPERATOR_VERSIONS="$OPP_OPERATOR_VERSION"
  else
    OPP_OPERATOR_VERSION="$(find $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME -type f -name "*.clusterserviceversion.yaml" | sort --version-sort | tail -n 1 | cut -d '/' -f 3)"
    OPP_OPERATOR_VERSIONS="$OPP_OPERATOR_VERSION"
  fi
fi

OPP_OPERATOR_VERSIONS_COUNT=0
[ -n "$OPP_OPERATOR_VERSIONS" ] && OPP_OPERATOR_VERSIONS_COUNT=$(echo $OPP_OPERATOR_VERSIONS | tr ' ' '\n' | wc -l)
OPP_OPERATOR_VERSIONS_REMOVED_COUNT=0
[ -n "$OPP_OPERATOR_VERSIONS_REMOVED" ] && OPP_OPERATOR_VERSIONS_REMOVED_COUNT=$(echo $OPP_OPERATOR_VERSIONS_REMOVED | tr ' ' '\n' | wc -l)


OPP_OPERATOR_VERSIONS_ALL_COUNT=0
[ -n "$OPP_OPERATOR_VERSIONS_ALL" ] && OPP_OPERATOR_VERSIONS_ALL_COUNT=$(echo $OPP_OPERATOR_VERSIONS_ALL | tr ' ' '\n' | wc -l)

echo "Versions Count: CHANGED[$OPP_OPERATOR_VERSIONS] REMOVED[$OPP_OPERATOR_VERSIONS_REMOVED]"

# [[ $OPRT -eq 1 ]] && [ -n "$OPP_OPERATOR_VERSIONS_REMOVED" ] && [[ ! $OPP_RECREATE -eq 1 ]] && [ "$OPP_OPERATOR_VERSIONS_REMOVED" != "$OPP_OPERATOR_VERSIONS_ALL_LATEST" ] && { echo "Error: Old versions [$OPP_OPERATOR_VERSIONS_REMOVED] were removed and 'allow/operator-recreate' is NOT set !!! Please set it first !!! Exiting ..."; echo "::set-output name=opp_error_code::6"; exit 1;  }
# [[ $OPP_OPERATOR_VERSIONS_COUNT -eq 1 ]] && [[ $OPP_IS_MODIFIED -eq 1 ]] && [[ $OPP_OPERATOR_VERSIONS_REMOVED_COUNT -gt 0 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0

[[ $OPP_OPERATOR_VERSIONS_COUNT -eq 1 ]] && [[ $OPP_IS_MODIFIED -eq 1 ]] && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=1
[[ $OPP_OPERATOR_VERSIONS_COUNT -eq 1 ]] && [[ $OPP_IS_MODIFIED -eq 1 ]] && [[ $OPP_OPERATOR_VERSIONS_REMOVED_COUNT -gt 0 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_OP_DELETE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0
[[ $OPP_OPERATOR_VERSIONS_COUNT -gt 1 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0
[[ $OPP_OPERATOR_VERSIONS_REMOVED_COUNT -gt 0 ]] && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_RECREATE=1 && OPP_OP_DELETE=1 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0 && OPP_VER_OVERWRITE=0
[[ $OPP_OPERATOR_VERSIONS_ALL_COUNT -eq 1 ]] && OPP_IS_NEW_OPERATOR=1 && OPP_RECREATE=1 && OPP_SET_LABEL_OPERATOR_RECREATE=1 && OPP_VER_OVERWRITE=0 && OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE=0

# [[ $OPRT -eq 0 ]] && [[ $OPP_OPERATOR_VERSIONS_COUNT -gt 1 ]] && [[ ! $OPP_RECREATE -eq 1 ]] && { echo "Error: Multiple versions [$OPP_OPERATOR_VERSIONS] were modified and 'allow/operator-recreate' is NOT set !!! Please set it first !!! Exiting ..."; echo "::set-output name=opp_error_code::5"; exit 1;  }


[[ $OPP_VER_OVERWRITE -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && { echo "Labels 'allow/operator-version-overwrite' and 'allow/operator-recreate' is set. Only one label can be set !!! Exiting ..."; echo "::set-output name=opp_error_code::1"; exit 1; }

# [[ $OPRT -eq 1 ]] && [[ $OPP_CI_YAML_MODIFIED -eq 1 ]] && [[ $OPP_CI_YAML_ONLY -eq 0 ]] && { echo "We support only a single file modification in case of 'ci.yaml' file. If you want to update it, please make an extra PR with 'ci.yaml' file modification only !!! More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/."; echo "::set-output name=opp_error_code::7"; exit 1; }

echo "::set-output name=opp_production_type::${OPP_PRODUCTION_TYPE}"
echo "::set-output name=opp_name::${OPP_OPERATOR_NAME}"

yq --version || { echo "Command 'yq' could not be found !!!"; exit 1; } 

# Hanlde remote ci.yaml for authorized changes
CI_YAML_REMOTE="https://raw.githubusercontent.com/$OPP_CURRENT_PROJECT_REPO/$OPP_CURRENT_PROJECT_BRANCH/$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml"
CI_YAML_REMOTE_LOCAL="/tmp/ci.yaml"
echo "Downloading '$CI_YAML_REMOTE' to $CI_YAML_REMOTE_LOCAL ... "
rm -f $CI_YAML_REMOTE_LOCAL
curl -s -f -o $CI_YAML_REMOTE_LOCAL $CI_YAML_REMOTE || true
if [ -f $CI_YAML_REMOTE_LOCAL ];then
  echo "File '$CI_YAML_REMOTE' was found ..."
  if [ -n "$OPP_PR_AUTHOR" ];then
    TEST_REVIEWERS=$(cat  $CI_YAML_REMOTE_LOCAL | yq '.reviewers')
    for row in $(echo "${TEST_REVIEWERS}" | yq -r '.[]'); do
      echo "checking if reviewer '$row' is pr author '$OPP_PR_AUTHOR' ..."
      if [ "${OPP_PR_AUTHOR,,}" == "${row,,}" ];then
        echo "[AUTHORIZED_CHANGES=1] : Author '${OPP_PR_AUTHOR,,}' is in reviewer list" && OPP_AUTHORIZED_CHANGES=1
      else
        OPP_REVIEVERS="@$row,$OPP_REVIEVERS"
      fi
    done
    OPP_REVIEVERS=$(echo $OPP_REVIEVERS | sed 's/\(.*\),/\1 /')
    [[ $OPP_AUTHORIZED_CHANGES -eq 1 ]] && OPP_REVIEVERS=""
  fi
else
  echo "File '$CI_YAML_REMOTE' was not found ..."
fi

if [[ $OPP_TEST_READY -eq 1 ]];then
  if [ -f $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml ];then 
    TEST_REVIEWERS=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq '.reviewers')
    # [ "$TEST_REVIEWERS" == "null" ] &&  { echo "We require that file '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' contains 'reviewers' array field with one reviewer set as minimum !!! More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/ !!!"; echo "::set-output name=opp_error_code::4"; exit 1; }
    
    if [ "$TEST_REVIEWERS" != "null" ];then
      TEST_REVIEWERS=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq '.reviewers | length' || echo 0)
      [[ $TEST_REVIEWERS -eq 0 ]] && { echo "We require that file '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' contains 'reviewers' array field and it has at least one reviewer set!!! More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/ !!!"; echo "::set-output name=opp_error_code::4"; exit 1; }
    else
      echo "File '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' doesn't contain 'reviewers' array field !!! If one wants to add reviewers (truested-authors) More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/. !!!"
      OPP_ERROR_CODE=10
    fi
    TEST_UPDATE_GRAPH=$(cat $OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml | yq '.updateGraph')
    [ $TEST_UPDATE_GRAPH == "null" ] && OPP_UPDATEGRAPH=0
    echo "OPP_UPDATEGRAPH=$OPP_UPDATEGRAPH"

  else
    echo "File '$OPP_OPERATORS_DIR/$OPP_OPERATOR_NAME/ci.yaml' is present !!! If one wants to add reviewers (truested-authors) More info : $OPP_CURRENT_PROJECT_DOC/operator-ci-yaml/. !!!"
    OPP_ERROR_CODE=10
  fi
fi

OPP_PR_TITLE="$OPP_OPERATORS_DIR"
[[ $OPRT -eq 1 ]] && [[ $OPP_VER_OVERWRITE -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [O]"
[[ $OPRT -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && [[ $OPP_IS_NEW_OPERATOR -eq 0 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [R]"
[[ $OPRT -eq 1 ]] && [[ $OPP_RECREATE -eq 1 ]] && [[ $OPP_IS_NEW_OPERATOR -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [N]"
[[ $OPRT -eq 1 ]] && [[ $OPP_CI_YAML_CHANGED -eq 1 ]] && OPP_PR_TITLE="$OPP_PR_TITLE [CI]"
OPP_PR_TITLE="$OPP_PR_TITLE $OPP_OPERATOR_NAME ($OPP_OPERATOR_VERSIONS)"

echo "Latest : $LATEST"
echo "OPP_OPERATOR_VERSION: $OPP_OPERATOR_VERSION"
echo "OPP_OPERATOR_VERSIONS : $OPP_OPERATOR_VERSIONS"
echo "OPP_OPERATOR_VERSIONS_ALL : $OPP_OPERATOR_VERSIONS_ALL"
echo "OPP_OPERATOR_VERSIONS_ALL_LATEST : $OPP_OPERATOR_VERSIONS_ALL_LATEST"
echo "OPP_OPERATOR_VERSIONS_REMOVED : $OPP_OPERATOR_VERSIONS_REMOVED"
echo "OPP_CHANGES_GITHUB=$OPP_CHANGES_GITHUB"
echo "OPP_CHANGES_CI=$OPP_CHANGES_CI"
echo "OPP_CHANGES_DOC=$OPP_CHANGES_DOCS"
echo "OPP_CHANGES_IN_OPERATORS_DIR=$OPP_CHANGES_IN_OPERATORS_DIR"
echo "OPP_CHANGES_STREAM_UPSTREAM=$OPP_CHANGES_STREAM_UPSTREAM"
echo "OPP_CHANGES_DOCKERFILE=$OPP_CHANGES_DOCKERFILE"

echo "opp_test_ready=${OPP_TEST_READY}"
echo "opp_release_ready=${OP_RELEASE_READY}"
echo "opp_production_type=${OPP_PRODUCTION_TYPE}"
echo "opp_name=${OPP_OPERATOR_NAME}"
echo "opp_version=${OPP_OPERATOR_VERSION}"
echo "opp_versions=${OPP_OPERATOR_VERSIONS}"
echo "opp_is_new_operatror=${OPP_IS_NEW_OPERATOR}"
echo "opp_pr_title=${OPP_PR_TITLE}"
echo "opp_pr_revievers=${OPP_REVIEVERS}"

echo "opp_ci_yaml_only=$OPP_CI_YAML_ONLY"
echo "opp_ci_yaml_changed=${OPP_CI_YAML_CHANGED}"
echo "opp_op_delete=$OPP_OP_DELETE"
echo "opp_ver_overwrite=$OPP_VER_OVERWRITE"
echo "opp_recreate=${OPP_RECREATE}"
echo "opp_set_label_operator_version_overwrite=$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE"
echo "opp_set_label_operator_recreate=$OPP_SET_LABEL_OPERATOR_RECREATE"
echo "opp_dockerfile_changed=$OPP_CHANGES_DOCKERFILE"

echo "opp_error_code=$OPP_ERROR_CODE"
echo "opp_authorized_changes=$OPP_AUTHORIZED_CHANGES"

echo "::set-output name=opp_test_ready::${OPP_TEST_READY}"
echo "::set-output name=opp_release_ready::${OP_RELEASE_READY}"

echo "::set-output name=opp_production_type::${OPP_PRODUCTION_TYPE}"
echo "::set-output name=opp_name::${OPP_OPERATOR_NAME}"
echo "::set-output name=opp_version::${OPP_OPERATOR_VERSION}"
echo "::set-output name=opp_versions::${OPP_OPERATOR_VERSIONS}"
echo "::set-output name=opp_is_new_operatror::${OPP_IS_NEW_OPERATOR}"
echo "::set-output name=opp_pr_title::${OPP_PR_TITLE}"
echo "::set-output name=opp_pr_revievers::${OPP_REVIEVERS}"


echo "::set-output name=opp_ci_yaml_only::${OPP_CI_YAML_ONLY}"
echo "::set-output name=opp_ci_yaml_changed::${OPP_CI_YAML_CHANGED}"

echo "::set-output name=opp_op_delete::${OPP_OP_DELETE}"
echo "::set-output name=opp_ver_overwrite::${OPP_VER_OVERWRITE}"
echo "::set-output name=opp_recreate::${OPP_RECREATE}"
echo "::set-output name=opp_update_graph::${OPP_UPDATEGRAPH}"

echo "::set-output name=opp_set_label_operator_version_overwrite::$OPP_SET_LABEL_OPERATOR_VERSION_OVERWRITE"
echo "::set-output name=opp_set_label_operator_recreate::$OPP_SET_LABEL_OPERATOR_RECREATE"
echo "::set-output name=opp_is_modified::$OPP_IS_MODIFIED"
echo "::set-output name=opp_modified_csvs::$OPP_MODIFIED_CSVS"
echo "::set-output name=opp_modified_others::$OPP_MODIFIED_OTHERS"
echo "::set-output name=opp_error_code::$OPP_ERROR_CODE"
echo "::set-output name=opp_authorized_changes::${OPP_AUTHORIZED_CHANGES}"
echo "::set-output name=opp_dockerfile_changed::$OPP_CHANGES_DOCKERFILE"

echo "All done"
exit 0

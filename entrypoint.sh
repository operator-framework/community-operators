#!/bin/bash

urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%s' "$c" | xxd -p -c1 |
                   while read c; do printf '%%%s' "$c"; done ;;
        esac
    done
}

urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

set -e

if [ -z "$webhook_url" ]; then
    echo "No webhook_url configured"
    exit 1
fi

if [ -z "$webhook_secret" ]; then
    echo "No webhook_secret configured"
    exit 1
fi

if [ -n "$webhook_type" ] && [ "$webhook_type" == "form-urlencoded" ]; then

    EVENT=`urlencode "$GITHUB_EVENT_NAME"`
    REPOSITORY=`urlencode "$GITHUB_REPOSITORY"`
    COMMIT=`urlencode "$GITHUB_SHA"`
    REF=`urlencode "$GITHUB_REF"`
    HEAD=`urlencode "$GITHUB_HEAD_REF"`
    WORKFLOW=`urlencode "$GITHUB_WORKFLOW"`

    CONTENT_TYPE="application/x-www-form-urlencoded"
    WEBHOOK_DATA="event=$EVENT&repository=$REPOSITORY&commit=$COMMIT&ref=$REF&head=$HEAD&workflow=$WORKFLOW"

    if [ -n "$data" ]; then
        WEBHOOK_DATA="${WEBHOOK_DATA}&${data}"
    fi

else

    CONTENT_TYPE="application/json"

    if [ -n "$webhook_type" ] && [ "$webhook_type" == "json-extended" ]; then
        RAW_FILE_DATA=`cat $GITHUB_EVENT_PATH`
        WEBHOOK_DATA=$(echo -n "$RAW_FILE_DATA" | jq -c '')
    else
        WEBHOOK_DATA="{\"event\":\"$GITHUB_EVENT_NAME\",\"repository\":\"$GITHUB_REPOSITORY\",\"commit\":\"$GITHUB_SHA\",\"ref\":\"$GITHUB_REF\",\"head\":\"$GITHUB_HEAD_REF\",\"workflow\":\"$GITHUB_WORKFLOW\"}"
    fi

    if [ -n "$data" ]; then
        CUSTOM_JSON_DATA=$(echo -n "$data" | jq -c '')
        JSON_WITH_OPEN_CLOSE_BRACKETS_STRIPPED=`echo "$WEBHOOK_DATA" | sed 's/^{\(.*\)}$/\1/'`
        WEBHOOK_DATA="{$JSON_WITH_OPEN_CLOSE_BRACKETS_STRIPPED,\"data\":$CUSTOM_JSON_DATA}"
    fi

fi

WEBHOOK_SIGNATURE=$(echo -n "$WEBHOOK_DATA" | openssl sha256 -hmac "$webhook_secret" -binary | xxd -p)
WEBHOOK_ENDPOINT=$webhook_url

if [ -n "$webhook_auth" ]; then
    WEBHOOK_ENDPOINT="-u $webhook_auth $webhook_url"
fi


if [ "$silent" ]; then
    curl -k -v --fail -s \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "User-Agent: User-Agent: GitHub-Hookshot/760256b" \
        -H "X-Hub-Signature: sha256=$WEBHOOK_SIGNATURE" \
        -H "X-GitHub-Delivery: $GITHUB_RUN_NUMBER" \
        -H "X-GitHub-Event: $GITHUB_EVENT_NAME" \
        --data "$WEBHOOK_DATA" $WEBHOOK_ENDPOINT &> /dev/null
else
    curl -k -v --fail \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "User-Agent: User-Agent: GitHub-Hookshot/760256b" \
        -H "X-Hub-Signature-256: sha256=$WEBHOOK_SIGNATURE" \
        -H "X-GitHub-Delivery: $GITHUB_RUN_NUMBER" \
        -H "X-GitHub-Event: $GITHUB_EVENT_NAME" \
        --data "$WEBHOOK_DATA" $WEBHOOK_ENDPOINT
fi
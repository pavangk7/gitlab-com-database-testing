#! /bin/sh
set -e

alias encode='python3 -c "import sys, urllib.parse as parse; print (parse.quote_plus(sys.argv[1]))"'

GITLAB_BRANCH=master
echo "$CI_MERGE_REQUEST_TITLE" | grep '\[gitlab_branch=' > /dev/null && GITLAB_BRANCH=$(expr "$CI_MERGE_REQUEST_TITLE" : '.*\[gitlab_branch=\([^]]*\)]')

echo "Getting latest commit from $GITLAB_BRANCH"

curl "https://gitlab.com/api/v4/projects/278964/repository/commits/$(encode "$GITLAB_BRANCH")" > latest_commit.json
SHA=$(jq .id < latest_commit.json)

echo "Triggering build on https://ops.gitlab.net/gitlab-com/database-team/gitlab-com-database-testing/-/pipelines from gitlab sha $SHA"
curl --fail-with-body \
     --request POST \
     --form "token=$TESTING_TRIGGER_TOKEN" \
     --form "ref=$CI_COMMIT_REF_NAME" \
     --form "variables[TOP_UPSTREAM_MERGE_REQUEST_IID]=$CI_MERGE_REQUEST_IID" \
     --form "variables[TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID]=$CI_MERGE_REQUEST_PROJECT_ID" \
     --form "variables[TOP_UPSTREAM_SOURCE_JOB]=$CI_JOB_URL" \
     --form "variables[TOP_UPSTREAM_SOURCE_PROJECT]=$CI_PROJECT_ID" \
     --form "variables[VALIDATION_PIPELINE]=true" \
     --form "variables[GITLAB_COMMIT_SHA]=$SHA" \
     --form "variables[TRIGGER_SOURCE]=$CI_JOB_URL" \
     "https://ops.gitlab.net/api/v4/projects/429/trigger/pipeline"

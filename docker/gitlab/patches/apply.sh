#!/bin/bash

set -eu

git am < 0001-Disable-AssetProxyFilter-initializer.patch
git am < 0002-Disable-automatic-schema-dumping-after-migration.patch

# In 138eb89534236164f1aec648fd192ba8c3cd20d3, gitlab begins to support GITLAB_SIMULATE_SAAS=true
# to pretend we are gitlab.com. This change also breaks the below patch.
# We temporarily apply the patch to previous versions for backwards compatibility.
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80755 for the gitlab change.
if ! git merge-base --is-ancestor 138eb89534236164f1aec648fd192ba8c3cd20d3 HEAD; then
  git am < 0003-Pretend-we-are-GitLab.com-for-testing-only.patch
fi
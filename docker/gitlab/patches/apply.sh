#!/bin/bash

set -eu

# Patches are in the same directory as this script
BASE_PATH=$(dirname "$0")

git am < "$BASE_PATH"/0001-Disable-AssetProxyFilter-initializer.patch
git am < "$BASE_PATH"/0002-Disable-automatic-schema-dumping-after-migration.patch

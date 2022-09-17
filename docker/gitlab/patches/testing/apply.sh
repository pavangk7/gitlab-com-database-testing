#!/bin/bash

set -e

for PATCH in /gitlab/patches/testing/*.patch; do
  echo "Applying patch file ${PATCH}"
  git am < $PATCH
done

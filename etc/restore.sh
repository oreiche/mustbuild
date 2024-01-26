#!/bin/bash

set -eu

readonly PATCH_DIR="$(mktemp -d)"

cp patches/*.patch "$PATCH_DIR"/.

git checkout $(cat justbuild.commit)
git am -k "$PATCH_DIR"/*
git branch patches -f

rm -rf "$PATCH_DIR"

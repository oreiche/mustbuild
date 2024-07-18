#!/bin/sh

set -eu

readonly ROOT="$(realpath $(dirname $0)/..)"
readonly BASE_COMMIT="$(git merge-base patches justbuild/stable-1.3)"
readonly PATCHDIR="${ROOT}/patches"

( cd "${PATCHDIR}"
  rm -f *
  git format-patch -k ${BASE_COMMIT}..patches > series
  sed -i '1d' *.patch                       # remove git commit id
  sed -i '$d' *.patch; sed -i '$d' *.patch  # remove git version
  sed -i '/^index\ [0-9a-f]\{8\}\.\.[0-9a-f]\{8\}\ [0-9]*/d' *.patch # remove git index
)

git show patches:src/jsonnet/builtins.libsonnet \
  | sed -n 's|^///\ \?\(.*\)|\1|p' > "${ROOT}/doc/must-lang.md"

echo "${BASE_COMMIT}" > ${ROOT}/justbuild.commit

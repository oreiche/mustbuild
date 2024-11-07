#!/bin/sh
#
# "Patch commit script", use with this alias in your ~/.bashrc:
#   alias pcommit='sh -c "$(git show master:etc/commit.sh)" "$(git rev-parse --show-toplevel)/etc/commit.sh" $1'

set -eu

readonly ROOT="$(realpath $(dirname $0)/..)"
readonly BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [ -z "${1:-}" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Import and commit patches to master branch"
  echo "  usage: $(basename $0) <message>"
  exit 1
fi

if [ "$BRANCH" != "patches" ]; then
  echo "error: not on branch 'patches'"
  exit 1
fi

( cd "$ROOT"
  git checkout stable-1.1
  ./etc/import.sh
  git add doc patches justbuild.commit
  if [ -z "$(git status --porcelain --untracked-files=no)" ]; then
    echo "nothing to commit"
  else
    git commit -m"$1"
  fi
  git checkout patches
)

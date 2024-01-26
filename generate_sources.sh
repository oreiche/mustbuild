#!/bin/sh

set -eu

if [ "${1:-}" = "-h" ]; then
  echo "usage: $(basename $0) [srcs_dir [dist_dir]]"
  echo
  echo "positionals:"
  echo "  srcs_dir      Output sources directory (default: ./srcs)"
  echo "  dist_dir      Directory for storing archives (default: ~/.distfiles)"
  exit 0
fi

readonly ROOT="$(realpath $(dirname $0))"
readonly SRCSDIR="$(realpath -m "${1:-$(pwd)/srcs}")"
readonly DISTDIR="$(realpath -m "${2:-${HOME}/.distfiles}")"
readonly PATCHDIR="${ROOT}/patches"

readonly BASE_COMMIT="$(cat "${ROOT}/justbuild.commit")"
readonly FETCH_URL="https://github.com/just-buildsystem/justbuild/archive/${BASE_COMMIT}.tar.gz"
readonly ARCHIVE="${DISTDIR}/${BASE_COMMIT}.tar.gz"

mkdir -p "${DISTDIR}"
if [ ! -f "${ARCHIVE}" ]; then
  echo "Fetching Justbuild archive to ${DISTDIR}"
  wget -q -O "${ARCHIVE}" "${FETCH_URL}"
fi

mkdir -p "${SRCSDIR}"
( cd "${SRCSDIR}"
  echo "Unpacking sources to ${SRCSDIR}"
  tar -xf "${ARCHIVE}" --strip-components=1 -C "."
  echo "Patching sources"
  for p in $(cat "${PATCHDIR}/series"); do
    patch -p1 < "${PATCHDIR}/$p" >/dev/null
  done
)

echo SUCCESS

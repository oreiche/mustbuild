#!/bin/bash

set -eu

: ${BUILDDIR:=/tmp/build}

NAME=mustbuild-$VERSION-$TARGET_ARCH-linux
OUTDIR=$(pwd)/../$NAME

MI_CC="gcc"
if [ "$TARGET_ARCH" = "aarch64" ]; then
  MI_CC="aarch64-linux-musl-gcc"
  TARGET_ARCH="arm64"
fi

mkdir -p "${BUILDDIR}"
rm -rf "${BUILDDIR}"/*

# build mimalloc.o from source
( cd "${BUILDDIR}"
  export GIT_SSL_NO_VERIFY=true
  git clone --depth 1 -b v2.1.2 https://github.com/microsoft/mimalloc.git
  MI_CFLAGS="-std=gnu11 -O3 -DNDEBUG -DMI_MALLOC_OVERRIDE -I./mimalloc/include \
      -fPIC -fvisibility=hidden -ftls-model=initial-exec -fno-builtin-malloc"
  ${MI_CC} ${MI_CFLAGS} -c ./mimalloc/src/static.c -o mimalloc.o
)

MIMALLOC_OBJ="${BUILDDIR}/mimalloc.o"
if [ ! -f "$MIMALLOC_OBJ" ]; then
  echo "Could not find mimalloc.o"
  exit 1
fi

cat > build.conf << EOF
{ "TOOLCHAIN_CONFIG":
  { "FAMILY": "gnu"
  , "BUILD_STATIC": true
  }
, "TARGET_ARCH": "$TARGET_ARCH"
, "AR": "ar"
, "SOURCE_DATE_EPOCH": $SOURCE_DATE_EPOCH
, "VERSION_EXTRA_SUFFIX": "$GIT_VERSION_SUFFIX"
, "FINAL_LDFLAGS": ["$MIMALLOC_OBJ"]
, "PANDOC_ENV": {"HOME": "$HOME"}
}
EOF

sed -i 's/"to_git": true/"to_git": false/g' etc/repos.json
if ldd 2>&1 | grep musl >/dev/null; then
  sed -i 's/linux-gnu/linux-musl/g' etc/toolchain/CC/TARGETS
fi

if just-mr version >/dev/null 2>&1; then
  # build with justbuild
  just-mr --no-fetch-ssl-verify --local-build-root ${BUILDDIR}/.must install \
    -c build.conf -o ${OUTDIR} ALL
else
  # build via full bootstrap
  export JUST_BUILD_CONF="$(cat build.conf)"
  BOOTSTRAP_TARGET=ALL python3 ./bin/bootstrap.py . ${BUILDDIR} ${DISTFILES}
  mkdir -p ${OUTDIR}
  cp -ra ${BUILDDIR}/out/. ${OUTDIR}/.
fi

cd $OUTDIR/..
tar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 1970-01-01' -czvf $NAME.tar.gz $NAME

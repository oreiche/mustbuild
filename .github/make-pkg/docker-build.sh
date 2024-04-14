#!/bin/bash

set -euo pipefail

readonly TEMP=$(mktemp -d)
readonly REF="${1:-HEAD}"
shift

readonly ROOTDIR=$(realpath $(dirname $0))
FAIL_COUNT=0

function docker_build() {
  local NAME=$1
  local PKG=$(jq -r '."'${NAME}'".type' ${ROOTDIR}/platforms.json)
  local IMAGE=$(jq -r '."'${NAME}'".image' ${ROOTDIR}/platforms.json)
  local PREBUILT=$(jq -r '."'${NAME}'".prebuilt // ""' ${ROOTDIR}/platforms.json)
  local BUILD_DEPS=$(jq -r '."'${NAME}'"."build-depends" // [] | join(" ")' \
                        ${ROOTDIR}/platforms.json)
  local BUILD_DIR="$(pwd)/work_${NAME}/build"
  local DOCKER_ARGS="-w /workspace -v $(pwd):/workspace -v ${BUILD_DIR}:/tmp/build"

  if [ -t 0 ]; then
    DOCKER_ARGS="-it ${DOCKER_ARGS}"
  fi

  # create build dir and clean success flag
  mkdir -p "${BUILD_DIR}"
  rm -f ./work_${NAME}/success

  local TARBALL=""
  if [ -n "${PREBUILT}" ]; then
    # generate the tarball first by calling ourselfs for the "prebuilt" target
    $0 $REF ${PREBUILT}
    TARBALL="/workspace/$(ls work_${PREBUILT}/source/mustbuild-*.tar.gz)"
  fi

  # generate docker file
  mkdir -p ${TEMP}
  if [ "${PKG}" = "deb" ]; then
    cat > ${TEMP}/Dockerfile.${NAME} << EOL
FROM ${IMAGE}
ENV HOME=/tmp/nobody
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y jq git wget dh-make
RUN apt update && apt install -y bash ${BUILD_DEPS}
EOL
  elif [ "${PKG}" = "rpm" ]; then
    cat > ${TEMP}/Dockerfile.${NAME} << EOL
FROM ${IMAGE}
ENV HOME=/tmp/nobody
RUN dnf install -y jq git wget make rpmdevtools
RUN dnf install -y bash ${BUILD_DEPS}
EOL
  elif [ "${PKG}" = "tar" ]; then
    cat > ${TEMP}/Dockerfile.${NAME} << EOL
FROM ${IMAGE}
ENV HOME=/tmp/nobody
ENV SSL_NO_VERIFY_PEER=1
RUN xbps-install -Syu xbps
RUN xbps-install -Syu bash justbuild ${BUILD_DEPS}
EOL
  else
    echo "Unsupported pkg type '${PKG}'"
    exit 1
  fi

  # build docker image
  docker build -f ${TEMP}/Dockerfile.${NAME} -t must-make-${PKG}:${NAME} ${TEMP}

  # build package
  docker run ${DOCKER_ARGS} -u $(id -u):$(id -g) must-make-${PKG}:${NAME} \
    .github/make-pkg/build.sh ${REF} ${NAME} ${PKG} ${TARBALL}

  if [ "${PKG}" = "deb" ] && [ -f ./work_${NAME}/source/mustbuild_*.deb ]; then
    # verify deb package
    docker run ${DOCKER_ARGS} ${IMAGE} /bin/bash -c "\
      set -e; \
      export DEBIAN_FRONTEND=noninteractive; \
      apt update; \
      apt install --no-install-recommends -y ./work_${NAME}/source/mustbuild_*.deb; \
      must version; \
      if [ $? = 0 ]; then touch ./work_${NAME}/success; fi"
  elif [ "${PKG}" = "rpm" ] && [ -f ./work_${NAME}/source/rpmbuild/RPMS/x86_64/mustbuild-*.rpm ]; then
    # verify rpm package
    docker run ${DOCKER_ARGS} ${IMAGE} /bin/bash -c "\
      set -e; \
      dnf install --setopt=install_weak_deps=False -y ./work_${NAME}/source/rpmbuild/RPMS/x86_64/mustbuild-*rpm; \
      must version; \
      if [ $? = 0 ]; then touch ./work_${NAME}/success; fi"
  elif [ "${PKG}" = "tar" ] && [ -f ./work_${NAME}/source/mustbuild-*.tar.gz ]; then
    if [ -f ./work_${NAME}/source/mustbuild-*-x86_64-linux.tar.gz ]; then
      # verify tarball
      docker run ${DOCKER_ARGS} ${IMAGE} /bin/sh -c "\
        set -e; \
        export SSL_NO_VERIFY_PEER=1; \
        xbps-install -Syu xbps; \
        xbps-install -Syu tar gzip; \
        mkdir -p /tmp/testroot; \
        tar -xvf ./work_${NAME}/source/mustbuild-*.tar.gz --strip-components=1 -C /tmp/testroot; \
        export PATH=/tmp/testroot/bin:\$PATH; \
        must version; \
        if [ $? = 0 ]; then touch ./work_${NAME}/success; fi"
    else
      touch ./work_${NAME}/success
    fi
  fi
}

function report() {
  local NAME=$1
  if [ -f work_${NAME}/success ]; then
    echo PASS: ${NAME}
  else
    echo FAIL: ${NAME}
    FAIL_COUNT=$((${FAIL_COUNT}+1))
  fi
}

if [ "${#@}" = 0 ]; then
  # build all if not specified otherwise
  set -- $(jq -r 'keys | .[]' "${ROOTDIR}/platforms.json" | xargs)
fi

( set +e
  for PLATFORM in "$@"; do
    docker_build ${PLATFORM}
  done
  exit 0
)

for PLATFORM in "$@"; do
  report ${PLATFORM}
done

rm -rf ${TEMP}

exit ${FAIL_COUNT}

#!/bin/bash
#
# This script runs the TimescaleDB tests through a standard PostgreSQL
# container, first installing the extension via a mounted host volume.
#
SCRIPT_DIR=$(dirname $0)
BASE_DIR=${PWD}/${SCRIPT_DIR}/..
PG_IMAGE_TAG=${PG_IMAGE_TAG:-9.6.3-alpine}
CONTAINER_NAME=${CONTAINER_NAME:-pgtest}

case $1 in
    clean)
        docker rm -f $(docker ps -a -q -f name=${CONTAINER_NAME} 2>/dev/null) 2>/dev/null
        ;;
esac

if [ $(docker ps -q -f name=${CONTAINER_NAME} 2>/dev/null | wc -l) = 0 ]; then
    echo "Creating container ${CONTAINER_NAME}"
    docker rm ${CONTAINER_NAME} 2>/dev/null
    # Run a Postgres container
    docker run -u postgres -d --name ${CONTAINER_NAME} -v ${BASE_DIR}:/src postgres:${PG_IMAGE_TAG}
    # Install build dependencies
    docker exec -u root -it ${CONTAINER_NAME} /bin/bash -c "apk add --no-cache --virtual .build-deps coreutils dpkg-dev gcc libc-dev make util-linux-dev diffutils && mkdir -p /build"
fi

# Copy the source files to build directory
docker exec -u root -it ${CONTAINER_NAME} /bin/bash -c "cp -a /src/{src,sql,test,Makefile,timescaledb.control} /build/ &&  make -C /build clean && make -C /build install"

# Run tests
docker exec -u postgres -it ${CONTAINER_NAME} /bin/bash -c "make -C /build installcheck TEST_INSTANCE_OPTS='--temp-instance=/tmp/pgdata --temp-config=/build/test/postgresql.conf'"

if [ "$?" != "0" ]; then
    docker exec -it ${CONTAINER_NAME} cat /build/test/regression.diffs
fi

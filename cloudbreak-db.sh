#!/usr/bin/env bash
$(cbd env export) &> /dev/null

if [[ -z ${CB_DB_PORT_5432_TCP_ADDR} ]] || [[ -z ${CB_DB_PORT_5432_TCP_PORT} ]]; then
    echo "No custom DB settings detected, exiting"
    exit 0
fi

set -eu

export PGPASSWORD=${CB_DB_ENV_PASS}

declare -r DB_CONTAINER_EXEC=".deps/bin/docker-compose -p ${CB_COMPOSE_PROJECT} run --rm -e PGPASSWORD commondb -c"
declare -r DB_CONTAINER_ENV="-h ${CB_DB_PORT_5432_TCP_ADDR} -p ${CB_DB_PORT_5432_TCP_PORT} -U ${CB_DB_ENV_USER}"

db-execute() {
    ${DB_CONTAINER_EXEC} "\
        ${1} \
        ${DB_CONTAINER_ENV} \
        ${2}"
}

db-psql() {
    db-execute psql "${1}"
}

db-create() {
    db-execute createdb "${1}"
}

db-exists() {
    db-psql " -lqt" | cut -d \| -f 1 | grep -qw "${1}"
}


for db_name in cbdb uaadb periscopedb; do
    if ! db-exists ${db_name}; then
        echo "DB ${db_name} not found, creating!"
        db-create ${db_name}
    fi
done

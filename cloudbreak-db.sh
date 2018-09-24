#!/usr/bin/env bash

main() {
    (
        set -e

        cd ${CLOUDBREAK_HOME}

        import-cb-variables
        check-for-custom-db-or-exit

        set -u

        for db_name in cbdb uaadb periscopedb; do
            if ! db-exists ${db_name}; then
                echo "DB ${db_name} not found, creating!"
                db-create ${db_name}
            fi
        done
    )
}

import-cb-variables() {
    $(cbd env export) &> /dev/null \
        || echo "Failed to import SOME Cloudbreak variables"
}

check-for-custom-db-or-exit() {
    if [[ -z ${CB_DB_PORT_5432_TCP_ADDR} ]] || [[ -z ${CB_DB_PORT_5432_TCP_PORT} ]]; then
        echo "No custom DB settings detected, exiting"
        exit 0
    fi
}

db-execute() {
    local -xr PGHOST=${CB_DB_PORT_5432_TCP_ADDR}
    local -xr PGPORT=${CB_DB_PORT_5432_TCP_PORT}
    local -xr PGUSER=${CB_DB_ENV_USER}
    local -xr PGPASSWORD=${CB_DB_ENV_PASS}

    docker run \
        --rm \
        --env PGHOST \
        --env PGPORT \
        --env PGUSER \
        --env PGPASSWORD \
        postgres:${DOCKER_TAG_POSTGRES} \
        bash -c "${1}"
}

db-create() {
    db-execute "createdb ${1}"
}

db-exists() {
    db-execute "psql -lqt" | cut -d \| -f 1 | grep -qw "${1}"
}

main "${@}"

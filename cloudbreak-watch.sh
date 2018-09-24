#!/usr/bin/env bash

main() {
    (
        set -eu

        cd ${CLOUDBREAK_HOME}

        import-cb-variables

        while cloudbreak-available; do
            sleep 10
        done

        exit 1
    )
}

import-cb-variables() {
    $(cbd env export) &> /dev/null \
        || echo "Failed to import SOME Cloudbreak variables"
}

cloudbreak-available() {
    # status is only there if there is a non-standard response
    ! cbd util get-usage \
        | jq -re '.status' &> /dev/null
}

main "${@}"

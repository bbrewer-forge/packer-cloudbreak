#!/usr/bin/env bash

main() {
    set -eux

    install-dependencies
    install-software
    install-service-wrapper

    initialize-software
    smoke-test-software
    prepare-for-snapshot
}

install-dependencies() {
    yum install -y \
        yum-utils \
        device-mapper-persistent-data \
        lvm2 \
        unzip \
        tar \
        curl \
        gzip \
        shadow-utils \
        openssl \
        docker \
        jq

    systemctl enable docker
    systemctl start docker
}

install-software() {
    curl -Ls public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CLOUDBREAK_VERSION}_$(uname)_$(uname -m).tgz \
        | tar -xz -C /bin cbd
    cbd --version

    curl -Ls https://s3-us-west-2.amazonaws.com/cb-cli/cb-cli_${CLOUDBREAK_VERSION}_$(uname -s)_$(uname -m).tgz \
        | tar -xz -C /bin cb
    cb --version
}

install-service-wrapper() {
    install ${CLOUDBREAK_WATCH} /usr/bin/cloudbreak-watch
    install ${CLOUDBREAK_DB} /usr/bin/cloudbreak-db
    cat ${CLOUDBREAK_SERVICE} \
        | envsubst > /etc/systemd/system/cloudbreak.service
    env | grep CLOUDBREAK_HOME > /etc/sysconfig/cloudbreak
    systemctl daemon-reload
}

initialize-software() {
    mkdir -p ${CLOUDBREAK_HOME}
    mv ${CLOUDBREAK_PROFILE} ${CLOUDBREAK_HOME}

    systemctl enable cloudbreak
    systemctl start cloudbreak \
        || { journalctl -u cloudbreak; exit 1; }
}

smoke-test-software() {
    (
        cd ${CLOUDBREAK_HOME}

        set +x
        source Profile
        set -x

        timeout -k 9 5 cb blueprint list \
            || { echo "Failed to run cloudbreak command"; exit 1; }
    )
}

prepare-for-snapshot() {
    systemctl stop cloudbreak
    systemctl disable cloudbreak

    rm -rf \
       ${CLOUDBREAK_WATCH} \
       ${CLOUDBREAK_SERVICE} \
       ${CLOUDBREAK_DB}

    find ${CLOUDBREAK_HOME} -maxdepth 1 -mindepth 1 ! -name .deps \
        | xargs -r rm -rf
}

main "${@}"

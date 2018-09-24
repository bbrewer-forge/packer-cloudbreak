#!/usr/bin/env bash
set -eux

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

curl -Ls public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CLOUDBREAK_VERSION}_$(uname)_x86_64.tgz \
  | tar -xz -C /bin cbd
cbd --version

curl -Ls https://s3-us-west-2.amazonaws.com/cb-cli/cb-cli_${CLOUDBREAK_VERSION}_$(uname -s)_$(uname -m).tgz \
  | tar -xz -C /bin cb
cb --version

mkdir -p ${CLOUDBREAK_HOME}
cd ${CLOUDBREAK_HOME}

mv ${CLOUDBREAK_PROFILE} ${CLOUDBREAK_HOME}
install ${CLOUDBREAK_WATCH} /usr/bin/cloudbreak-watch
install ${CLOUDBREAK_DB} /usr/bin/cloudbreak-db
cat ${CLOUDBREAK_SERVICE} \
    | envsubst > /etc/systemd/system/cloudbreak.service
env | grep CLOUDBREAK_HOME > /etc/sysconfig/cloudbreak

systemctl daemon-reload
systemctl enable cloudbreak
systemctl start cloudbreak \
    || { journalctl -u cloudbreak; exit 1; }

(
    set +x
    source Profile
    set -x
    timeout -k 9 5 cb blueprint list \
        || { echo "Failed to run cloudbreak command"; exit 1; }
)

systemctl stop cloudbreak
systemctl disable cloudbreak

rm -rf /tmp/cloudbreak*
find . -maxdepth 1 -mindepth 1 ! -name .deps \
    | xargs -r rm -rf

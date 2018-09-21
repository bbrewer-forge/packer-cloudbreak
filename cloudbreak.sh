#!/usr/bin/env bash
set -e

declare -r cloudbreak_user=${1}
declare -r cloudbreak_home=${2}
declare -r cloudbreak_profile=${3}
declare -r cloudbreak_version=${4}

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
  docker

systemctl enable docker
systemctl start docker

curl -Ls public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${cloudbreak_version}_$(uname)_x86_64.tgz \
  | tar -xz -C /bin cbd
cbd --version

useradd -d ${cloudbreak_home} -G docker ${cloudbreak_user}
cd ${cloudbreak_home}
mv ${cloudbreak_profile} .

cbd generate
cbd pull-parallel

chown -R ${cloudbreak_user}:${cloudbreak_user} ${cloudbreak_home}

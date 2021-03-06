#!/bin/bash
. ./config/docker-machine-settings.sh
. ./scripts/docker-machine-common.sh

DOCKER_MACHINE_DEPLOY_HOME="~/deploy"

create-deploy-home-dir() {
  local NAME="$1"
  local DEPLOY_HOME="$2"

  docker-machine ssh "${NAME}" mkdir -pv "${DEPLOY_HOME}"
  return $?
}

deploy-cf-containers-broker-config() {
  local NAME="$1"
  local DEPLOY_HOME="$2"

  get-docker-machine-ip "${NAME}" || return $?
  sed -i '' -E "s/(external_ip:).*/\1 ${DOCKER_MACHINE_IP}/" deploy/config/cf-containers-broker/settings.yml

  get-docker-machine-host "${NAME}" || return $?
  sed -i '' -E "s/(external_host:).*/\1 ${DOCKER_MACHINE_HOST}/" deploy/config/cf-containers-broker/settings.yml

  docker-machine scp -r deploy/config "${NAME}:${DEPLOY_HOME}"
  return $?
}

run-cf-containers-broker() {
  local NAME="$1"

  get-docker-machine-env "${NAME}" || return $?

  docker run -d \
    --name cf-containers-broker \
    --publish 80:80 \
    --volume /var/run:/var/run \
    --volume /home/ubuntu/deploy/config/cf-containers-broker:/config \
    amayr/cf-containers-broker
  return $?
}

if ! create-deploy-home-dir "${DOCKER_MACHINE_NAME}" "${DOCKER_MACHINE_DEPLOY_HOME}"; then
  echo "Error: could not create deployment home directory ${DOCKER_MACHINE_DEPLOY_HOME}"; exit 1
fi

if ! deploy-cf-containers-broker-config "${DOCKER_MACHINE_NAME}" "${DOCKER_MACHINE_DEPLOY_HOME}"; then
  echo "Error: could not deploy cf-containers-broker configuration"; exit 1
fi

if ! run-cf-containers-broker "${DOCKER_MACHINE_NAME}"; then
  echo "Error: could not run cf-containers-broker"; exit 1
fi

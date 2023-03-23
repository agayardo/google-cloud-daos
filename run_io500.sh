#!/bin/bash

set -e

RESULT_NAME="cos-sx-clients16-servers4-targets16"
IO500_DIR="google-cloud-daos/terraform/examples/io500"

experimental/users/damok/daos_container/create_cos_vms.sh

ssh daos-controller "cd ${IO500_DIR}; ./stop.sh" || echo "stop failed ignoring"

rsync -avh --delete "${HOME}/google-cloud-daos" "daos-controller:~/"

ssh daos-controller "cd ${IO500_DIR}; ./start.sh -i"

SSH_CONFIG_FILE="${IO500_DIR}/tmp/ssh_config"
FIRST_CLIENT_IP=$(ssh daos-controller cat ${SSH_CONFIG_FILE} | awk '{print $2}' | grep 10)

mkdir -p "${HOME}/results/${RESULT_NAME}"
ssh daos-controller mkdir -p "${IO500_DIR}/results/${RESULT_NAME}"

ssh daos-controller ssh -F "${SSH_CONFIG_FILE}" "${FIRST_CLIENT_IP}" ./run_io500-isc22.sh | tee "${HOME}/results/${RESULT_NAME}.txt"
ssh daos-controller scp -F "${SSH_CONFIG_FILE}" -r "${FIRST_CLIENT_IP}:io500-isc22/results/*" "${IO500_DIR}/results/${RESULT_NAME}"

rsync -avh "daos-controller:${IO500_DIR}/results/${RESULT_NAME}" "${HOME}/results"


ssh daos-controller "cd ${IO500_DIR}; ./stop.sh"


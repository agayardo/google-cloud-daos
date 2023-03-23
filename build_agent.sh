#!/bin/bash
# This script builds the jumpbox container image in GCP Artificat Registry
# As part of the container daos agent is build.
# The container is built using GCP Cloud build which safes it in Artificat Registry.

set -e

MY_DIR=$(dirname "$0")
G3_ROOT=$(realpath "${MY_DIR}/../../../..")

CONTAINER_DIR="experimental/users/damok/daos_container/agent"
OUT_CONTAINER_DIR="${HOME}/tmp/daos-agent"
DAOS_AGENT_BIN="blaze-bin/cloud/hosted/daos/jumpbox/daosagent"

GCP_PROJECT="daos-sandbox"

prepare_container_dir() {
  cd "${G3_ROOT}"

  rm -rf "${OUT_CONTAINER_DIR}"
  mkdir -p "${OUT_CONTAINER_DIR}"
  cp "${CONTAINER_DIR}"/* "${OUT_CONTAINER_DIR}"
}

build_agent() {
  cd "${G3_ROOT}"

  blaze build --config=nocgo cloud/hosted/daos/jumpbox:daosagent
  cp "${DAOS_AGENT_BIN}" "${OUT_CONTAINER_DIR}"
}

gcloud_cloudbuild() {
  cd "${OUT_CONTAINER_DIR}"

  gcloud builds submit --region=us-central1 --timeout=18000s --project="${GCP_PROJECT}" .
}

main() {
  prepare_container_dir
  build_agent
  gcloud_cloudbuild
}

main

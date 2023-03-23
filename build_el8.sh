#!/bin/bash

set -e

MY_DIR=$(dirname "$0")
MY_DIR=$(realpath "${MY_DIR}")

GCP_PROJECT=`gcloud config get project`
# GCP_PROJECT="cloud-daos-longevity-testing"

BUILD_POOL="projects/${GCP_PROJECT}/locations/us-central1/workerPools/build-pool-1"

build_container() {
  cd "${MY_DIR}/el8"

  gcloud builds submit --region=us-central1 --timeout=18000s --project="${GCP_PROJECT}" --worker-pool="${BUILD_POOL}" .
}

main() {
  build_container
}

main
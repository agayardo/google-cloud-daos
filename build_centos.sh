#!/bin/bash

set -e

MY_DIR=$(dirname "$0")
MY_DIR=$(realpath "${MY_DIR}")

GCP_PROJECT="cloud-daos-perf-testing"

build_container() {
  cd "${MY_DIR}/centos"

  gcloud builds submit --region=us-central1 --timeout=18000s --project="${GCP_PROJECT}" .
}

main() {
  build_container
}

main
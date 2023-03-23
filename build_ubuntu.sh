#!/bin/bash
set -e

MY_DIR=$(dirname "$0")
MY_DIR=$(realpath "${MY_DIR}")

GCP_PROJECT="daos-sandbox"

build_server() {
  cd "${MY_DIR}/ubuntu"

  gcloud builds submit --region=us-central1 --timeout=18000s --project="${GCP_PROJECT}" .
}

main() {
  build_server
}

main
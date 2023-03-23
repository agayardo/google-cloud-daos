#!/bin/bash

METADATA=http://metadata.google.internal/computeMetadata/v1
SVC_ACCT=$METADATA/instance/service-accounts/default
ACCESS_TOKEN=$(/usr/bin/curl -s -H 'Metadata-Flavor: Google' $SVC_ACCT/token | cut -d'"' -f 4)

docker login --username oauth2accesstoken --password $ACCESS_TOKEN https://us-central1-docker.pkg.dev

# setup huge pages for daos
echo 8192 | sudo tee /proc/sys/vm/nr_hugepages

docker run -d --privileged --cap-add=ALL --name server --network host -v /dev:/dev \
    us-central1-docker.pkg.dev/cloud-daos-perf-testing/docker-registry/daos-server:latest

docker exec -it server bash
#!/bin/bash

set -e
set -m

GCP_DAOS_REPO_LOCAL_BASE="${GCP_DAOS_REPO_LOCAL_BASE:-${HOME}/gcp-daos}"

source "${GCP_DAOS_REPO_LOCAL_BASE}/terraform/examples/io500/config/config.sh"

ID="${ID:-$USER}"
GCP_PROJECT_NAME="${DAOS_PROJECT_NAME:-cloud-daos-perf-testing}"
GCP_ZONE="${TF_VAR_zone:-us-central1-f}"
MACHINE_TYPE="${DAOS_SERVER_MACHINE_TYPE:-n2-custom-36-262144}"
COS_VMS="${DAOS_SERVER_INSTANCE_COUNT:-17}"

GCP_PROJECT_NUMBER=$(gcloud projects describe "${GCP_PROJECT_NAME}" --format='value(projectNumber)')

CONTAINER_NAME="us-central1-docker.pkg.dev/${GCP_PROJECT_NAME}/docker-registry/${DOCKER_IMAGE}"

USER_DATA_FILE="experimental/users/damok/daos_container/cos/cloud-init"

HOSTLIST=($(for i in $(seq -f "%04g" 1 "${COS_VMS}")
do
  echo "daos-server-${ID}-$i"
done))

# odd number, 1, 3, 5
if [[ $COS_VMS -ge 3 ]]
then
  ACCESS_POINTS=(
    "daos-server-${ID}-0001"
    "daos-server-${ID}-0002"
    "daos-server-${ID}-0003"
  )
else
  ACCESS_POINTS=(
    "daos-server-${ID}-0001"
  )
fi

function wait_for_jobs() {
  while [[ $(jobs -p | wc -w) -ge $1 ]]
  do
    echo "Too many jobs, waiting"
    fg || true
  done
}

function fmtArray
{
  arr=("$@")
  t=$(printf "'%s'," "${arr[@]}")
  echo ${t%,}
}

HOSTLIST_STR=$(fmtArray "${HOSTLIST[@]}")
ACCESS_POINTS_STR=$(fmtArray "${ACCESS_POINTS[@]}")

# --maintenance-policy=TERMINATE \
# --provisioning-model=SPOT \
# --maintenance-policy=MIGRATE \
# --provisioning-model=STANDARD \

for NAME in "${HOSTLIST[@]}"; do
  wait_for_jobs 5
  gcloud compute instances create "${NAME}" \
    --project="${GCP_PROJECT_NAME}" \
    --zone="${GCP_ZONE}" \
    --machine-type="${MACHINE_TYPE}" \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --network-interface="network-tier=PREMIUM,subnet=default,nic-type=GVNIC" \
    --service-account="${GCP_PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --scopes="https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append" \
    --create-disk="auto-delete=yes,boot=yes,device-name=daos-cos,image=projects/cos-cloud/global/images/cos-101-17162-40-38,mode=rw,size=100,type=projects/${GCP_PROJECT_NAME}/zones/us-central1-f/diskTypes/pd-balanced" \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --local-ssd=interface=NVME \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any \
    --min-cpu-platform="Intel Ice Lake" \
    --threads-per-core=1 \
    --visible-core-count=18 \
    --network-performance-configs=total-egress-bandwidth-tier=TIER_1 \
    --metadata "^;^access-points=${ACCESS_POINTS_STR};hostlist=${HOSTLIST_STR};container-name=${CONTAINER_NAME}" \
    --metadata-from-file "user-data=${USER_DATA_FILE}" &
done

# --network-performance-configs=total-egress-bandwidth-tier=TIER_1
# nic-type=VIRTIO_NET or GVNIC

wait

echo "sleep 15"
sleep 15

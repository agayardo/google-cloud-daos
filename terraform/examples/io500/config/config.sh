#!/bin/bash
# Copyright 2022 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# ------------------------------------------------------------------------------
# Configure the following variables to meet your specific needs
# ------------------------------------------------------------------------------
# Optional identifier to allow multiple DAOS clusters in the same GCP
# project by using this ID in the DAOS server and client instance names.
# Typically, this would contain the username of each user who is running
# the terraform/examples/io500/start.sh script in one GCP project.
# This should be set to a constant value and not the value of an
# environment variable such as '${USER}' which changes depending on where this
# file gets sourced.
ID="artemgm"

# Server and client instances
PREEMPTIBLE_INSTANCES="false"
SSH_USER="daos-user"
DAOS_ALLOW_INSECURE="true"

DOCKER_IMAGE="daos-el8-ld-preload-pil4dfs"
CLIENT_IMAGE="daos-client-io500-rocky-preload-pil4dfs"

# Server(s)
DAOS_SERVER_INSTANCE_COUNT=6
DAOS_SERVER_MACHINE_TYPE=n2-custom-36-262144

 # n2-custom-36-262144 # n2-highmem-32 #n2-custom-36-262144  # n2-custom-36-262144 # n2-highmem-32 #n2-custom-36-262144 # n2-custom-24-196608 # n2-custom-36-262144 # n2-custom-20-131072 n2-custom-40-262144 n2-highmem-32 n2-standard-2
DAOS_SERVER_DISK_COUNT=16
DAOS_SERVER_CRT_TIMEOUT=300
DAOS_SERVER_SCM_SIZE=200
DAOS_SERVER_GVNIC=true

# Client(s)
DAOS_CLIENT_INSTANCE_COUNT=1
DAOS_CLIENT_MACHINE_TYPE=c2-standard-30
DAOS_CLIENT_GVNIC=true

# Storage
DAOS_POOL_SIZE="$(awk -v disk_count=${DAOS_SERVER_DISK_COUNT} -v server_count=${DAOS_SERVER_INSTANCE_COUNT} 'BEGIN {pool_size = 375 * disk_count * server_count / 1000; print pool_size"TB"}')"
DAOS_CONT_REPLICATION_FACTOR=rf:0,ec_cell_sz:131072

# IO500
IO500_STONEWALL_TIME=180  # Number of seconds to run the benchmark

# Use DFUSE
DAOS_API="DFS"

IO500_NP_SCALE=2

# ------------------------------------------------------------------------------
# Modify instance base names if ID variable is set
# ------------------------------------------------------------------------------
DAOS_SERVER_BASE_NAME="${DAOS_SERVER_BASE_NAME:-daos-server}"
DAOS_CLIENT_BASE_NAME="${DAOS_CLIENT_BASE_NAME:-daos-client}"
if [[ -n ${ID} ]]; then
    DAOS_SERVER_BASE_NAME="${DAOS_SERVER_BASE_NAME}-${ID}"
    DAOS_CLIENT_BASE_NAME="${DAOS_CLIENT_BASE_NAME}-${ID}"
fi

# ------------------------------------------------------------------------------
# Terraform environment variables
# It's rare that these will need to be changed.
# ------------------------------------------------------------------------------
export TF_VAR_project_id="$(gcloud info --format="value(config.project)")"
export TF_VAR_network="default"
export TF_VAR_subnetwork="default"
export TF_VAR_subnetwork_project="${TF_VAR_project_id}"
export TF_VAR_region="us-central1"
export TF_VAR_zone="us-central1-b"
export TF_VAR_allow_insecure="${DAOS_ALLOW_INSECURE}"
# Servers
export TF_VAR_server_preemptible=${PREEMPTIBLE_INSTANCES}
export TF_VAR_server_number_of_instances=${DAOS_SERVER_INSTANCE_COUNT}
export TF_VAR_server_daos_disk_count=${DAOS_SERVER_DISK_COUNT}
export TF_VAR_server_daos_crt_timeout=${DAOS_SERVER_CRT_TIMEOUT}
export TF_VAR_server_daos_scm_size=${DAOS_SERVER_SCM_SIZE}
export TF_VAR_server_instance_base_name="${DAOS_SERVER_BASE_NAME}"
export TF_VAR_server_os_disk_size_gb=20
export TF_VAR_server_os_disk_type="pd-ssd"
export TF_VAR_server_template_name="${DAOS_SERVER_BASE_NAME}"
export TF_VAR_server_mig_name="${DAOS_SERVER_BASE_NAME}"
export TF_VAR_server_machine_type="${DAOS_SERVER_MACHINE_TYPE}"
export TF_VAR_server_os_project="${TF_VAR_project_id}"
export TF_VAR_server_os_family="daos-server-io500-rocky-linux-8-optimized-main" # rocky for real !
export TF_VAR_server_gvnic="${DAOS_SERVER_GVNIC}"
# Clients
export TF_VAR_client_preemptible=${PREEMPTIBLE_INSTANCES}
export TF_VAR_client_number_of_instances=${DAOS_CLIENT_INSTANCE_COUNT}
export TF_VAR_client_instance_base_name="${DAOS_CLIENT_BASE_NAME}"
export TF_VAR_client_os_disk_size_gb=20
export TF_VAR_client_os_disk_type="pd-ssd"
export TF_VAR_client_template_name="${DAOS_CLIENT_BASE_NAME}"
export TF_VAR_client_mig_name="${DAOS_CLIENT_BASE_NAME}"
export TF_VAR_client_machine_type="${DAOS_CLIENT_MACHINE_TYPE}"
export TF_VAR_client_os_project="${TF_VAR_project_id}"
export TF_VAR_client_os_family="${CLIENT_IMAGE}" 
export TF_VAR_client_gvnic="${DAOS_CLIENT_GVNIC}"

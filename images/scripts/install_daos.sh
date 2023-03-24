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

#
# Install DAOS Server or Client packages
#

set -e
trap 'echo "An unexpected error occurred. Exiting."' ERR

SCRIPT_NAME=$(basename "$0")

log() {
  # shellcheck disable=SC2155,SC2183
  local line=$(printf "%80s" | tr " " "-")
  if [[ -t 1 ]]; then tput setaf 14; fi
  printf -- "\n%s\n %-78s \n%s\n" "${line}" "${1}" "${line}"
  if [[ -t 1 ]]; then tput sgr0; fi
}

log_error() {
  # shellcheck disable=SC2155,SC2183
  if [[ -t 1 ]]; then tput setaf 160; fi
  printf -- "\n%s\n\n" "${1}" >&2;
  if [[ -t 1 ]]; then tput sgr0; fi
}


install_epel() {
  # DAOS has dependencies on packages in epel
  if ! rpm -qa | grep -q "epel-release"; then
    yum install -y epel-release
  fi
}

install_daos() {
  if [ ! -f $(which wget) ];then
    yum -y install wget
  fi

  yum -y install dnf git virtualenv

  dnf -y install epel-release dnf-plugins-core
  dnf config-manager --enable powertools
  # dnf group -y install "Development Tools"

  git clone --recurse-submodules https://github.com/daos-stack/daos.git  # --branch v2.2.0

  pushd daos
  git checkout lei/DAOS-12142

  dnf config-manager --save --setopt=assumeyes=True
  utils/scripts/install-el8.sh

  virtualenv myproject
  source myproject/bin/activate
  pip install --upgrade pip
  pip install defusedxml \
    distro \
    jira \
    junit_xml \
    meson \
    ninja \
    pyelftools \
    pyxattr \
    pyyaml \
    scons    \
    tabulate \
    wheel
  # pip install -r requirements.txt

  # --no-rpath
  scons --jobs="$(nproc --all)" --build-deps=only PREFIX=/usr TARGET_TYPE=release BUILD_TYPE=release

  ln -s /usr/prereq/release/spdk/lib/librte_eal.so.22.0 /usr/lib/librte_eal.so.22
  ln -s /usr/prereq/release/spdk/lib/librte_kvargs.so.22.0 /usr/lib/librte_kvargs.so.22
  ln -s /usr/prereq/release/spdk/lib/librte_telemetry.so.22.0 /usr/lib/librte_telemetry.so.22
  ln -s /usr/prereq/release/spdk/lib/librte_ring.so.22.0 /usr/lib/librte_ring.so.22
  ln -s /usr/prereq/release/spdk/lib/librte_pci.so.22.0 /usr/lib/librte_pci.so.22

  # --no-rpath
  scons --jobs="$(nproc --all)" install PREFIX=/usr TARGET_TYPE=release BUILD_TYPE=release CONF_DIR=/etc/daos 
   
  cp utils/systemd/daos_agent.service /etc/systemd/system
  cp utils/systemd/daos_server.service /etc/systemd/system

  popd

  useradd --no-log-init --user-group --create-home --shell /bin/bash daos_server
  echo "daos_server:daos_server" | chpasswd
  useradd --no-log-init --user-group --create-home --shell /bin/bash daos_agent
  echo "daos_agent:daos_agent" | chpasswd
  echo "daos_server ALL=(root) NOPASSWD: ALL" >> /etc/sudoers.d/daos_sudo_setup

  mkdir -p /var/run/daos_server
  mkdir -p /var/run/daos_agent
  chown -R daos_server.daos_server /var/run/daos_server
  chown daos_agent.daos_agent /var/run/daos_agent

  yum -y install kmod pciutils
  /usr/prereq/release/spdk/share/spdk/scripts/setup.sh

  systemctl disable daos_agent
}

install_additional_pkgs() {
  yum install -y clustershell curl git jq patch pdsh rsync wget
}

log "Installing DAOS"
install_epel
install_additional_pkgs
install_daos
printf "\n%s\n\n" "DONE! DAOS installed"

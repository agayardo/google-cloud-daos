FROM centos:centos7
LABEL maintainer="damok@google.com"

RUN curl -s --output /etc/yum.repos.d/daos_packages.repo "https://packages.daos.io/v2.0.3/CentOS7/packages/x86_64/daos_packages.repo"
RUN yum install -y epel-release
RUN yum install -y daos-server daos-client

RUN mkdir -p /var/run/daos_server

RUN rm -rf /etc/daos
 
ENTRYPOINT exec /usr/bin/daos_server start
FROM ghcr.io/arvatoaws-labs/ubuntu:20.04 as sessionmanagerplugin

RUN apt-get update \
    && apt-get install -y curl \
    && curl -Lo "session-manager-plugin.deb" "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_$(if [[ $(uname -m) == 'aarch64' ]]; then echo 'arm64'; else echo '64bit'; fi)/session-manager-plugin.deb" \
    && dpkg -i "session-manager-plugin.deb"

FROM ghcr.io/arvatoaws-labs/ruby:3-alpine

COPY --from=sessionmanagerplugin /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/
RUN apk add git aws-cli bash alpine-sdk openssh-client
RUN rm -rf /root/.ssh/known_hosts
RUN mkdir /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
RUN gem install bundler
COPY ssh_config /root/.ssh/config
# RUN yum install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
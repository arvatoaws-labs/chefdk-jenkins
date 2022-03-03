FROM ghcr.io/arvatoaws-labs/ruby:bullseye

ENV DEBIAN_FRONTEND noninteractive

RUN unlink /bin/sh && ln -s /bin/bash /bin/sh
RUN apt-get update
RUN apt-get install -y curl git build-essentials openssh-client awscli
RUN rm -rf /root/.ssh/known_hosts
RUN mkdir /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
RUN gem install bundler
COPY ssh_config /root/.ssh/config

RUN curl -Lo "session-manager-plugin.deb" "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_$(if [[ $(uname -m) == 'aarch64' ]]; then echo 'arm64'; else echo '64bit'; fi)/session-manager-plugin.deb"
RUN dpkg -i "session-manager-plugin.deb"
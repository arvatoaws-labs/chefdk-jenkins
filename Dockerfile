FROM golang:1.15.3-alpine as ssm-builder

ARG VERSION=1.2.279.0

RUN set -ex && apk add --no-cache make git gcc libc-dev curl bash zip && \
    curl -sLO https://github.com/aws/session-manager-plugin/archive/${VERSION}.tar.gz && \
    mkdir -p /go/src/github.com && \
    tar xzf ${VERSION}.tar.gz && \
    mv session-manager-plugin-${VERSION} /go/src/github.com/session-manager-plugin && \
    cd /go/src/github.com/session-manager-plugin && \
    make release

FROM ghcr.io/arvatoaws-labs/ruby:3-alpine

COPY --from=ssm-builder /go/src/github.com/session-manager-plugin/bin/linux_$(uname -m)_plugin/session-manager-plugin /usr/bin/
RUN apk add git aws-cli bash alpine-sdk openssh-client
RUN rm -rf /root/.ssh/known_hosts
RUN mkdir /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
RUN gem install bundler
COPY ssh_config /root/.ssh/config
# RUN yum install -y "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_$(if [[ $(uname -m) == 'aarch64' ]]; then echo 'arm64'; else echo '64bit'; fi)/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
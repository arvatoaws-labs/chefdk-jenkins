FROM ghcr.io/arvatoaws-labs/ruby:alpine

RUN apk add git aws-cli bash alpine-sdk openssh-client
RUN rm -rf ~/.ssh/known_hosts
RUN mkdir ~/.ssh
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
RUN gem install bundler
RUN bundle install
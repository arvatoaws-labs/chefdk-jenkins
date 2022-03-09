FROM public.ecr.aws/bitnami/ruby:3.1

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y curl git build-essential openssh-client awscli zlib1g-dev
RUN rm -rf /root/.ssh/known_hosts
RUN mkdir /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
RUN gem install bundler
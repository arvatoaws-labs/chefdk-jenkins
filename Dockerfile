FROM public.ecr.aws/bitnami/ruby:latest

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y curl git build-essential openssh-client awscli zlib1g-dev rsync librsync-dev ssh
RUN rm -rf /root/.ssh/known_hosts
RUN mkdir /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
RUN gem install bundler
ADD construct.rb /usr/bin

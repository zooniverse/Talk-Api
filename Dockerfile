FROM zooniverse/ruby:2.2.0

ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR /rails_app

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y supervisor && \
    apt-get clean

RUN cd /rails_app && \
    bundle install --without test development

ADD ./ /rails_app

ADD docker/supervisor.conf /etc/supervisor/conf.d/talk.conf

EXPOSE 80

ENTRYPOINT /usr/bin/supervisord

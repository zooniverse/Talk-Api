FROM ruby:2.4

WORKDIR /rails_app

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    git \
    libpq-dev \
    tmpreaper \
    && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ADD ./Gemfile /rails_app/
ADD ./Gemfile.lock /rails_app/

RUN bundle config --global jobs `cat /proc/cpuinfo | grep processor | wc -l | xargs -I % expr % - 1`
RUN bundle install --without development test

ADD ./ /rails_app

RUN (git log --format="%H" -n 1 > /rails_app/public/commit_id.txt && rm -rf .git)

EXPOSE 81

CMD [ "/rails_app/docker/start.sh" ]
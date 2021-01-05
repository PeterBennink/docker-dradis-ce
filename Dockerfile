FROM ruby:2.5-slim
LABEL maintainer "Christopher Snyder" <34378288+maliciousactor@users.noreply.github.com>

# environment config
ARG APT="-y --no-install-recommends --no-upgrade -o Dpkg::Options::=--force-confnew"
ENV RAILS_ENV development

# install dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install $APT build-essential gcc git libmariadbd-dev \
        libsqlite3-dev make nodejs patch zlib1g-dev yarn && \
# fetch and configure dradis
    git clone https://github.com/dradis/dradis-ce.git /app && \
    sed -i "s/ruby '2.4.1'/ruby '\>\= 2.4.1'/" /app/Gemfile && \
    sed -i 's@database:\s*db@database: /data@' /app/config/database.yml.template && \
    sed -i 's/config.force_ssl = true/config.force_ssl = false/' /app/config/environments/production.rb && \
    sed -i 's/:uglifier/Uglifier.new(harmony: true)/' /app/config/environments/production.rb && \
# ruby init
    gem update --system && \
# install dradis
    mkdir /data && \
    cd /app && ruby bin/setup && bundle exec rake assets:precompile && \
    sed -i '/gem/s/^# *//' /app/Gemfile.plugins && bundle install && \
# clean image
    DEBIAN_FRONTEND=noninteractive \
    apt remove -y --purge build-essential gcc libmariadbd-dev libsqlite3-dev make patch wget zlib1g-dev && \
    DEBIAN_FRONTEND=noninteractive apt install $APT libmariadb3 libsqlite3-0 zlib1g && \
    DEBIAN_FRONTEND=noninteractive apt autoremove -y && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* && \
    rm -rf /data/development.sqlite3

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

WORKDIR /app

VOLUME /app
VOLUME /data

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]

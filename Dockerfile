FROM ruby:3.3.12-slim@sha256:65bce1aa8dfc8758b8fadc4629a91d4cf621784b8dfb5fed265d6ed52b0a0fb3 as ruby

# Metadata
LABEL maintainer="open-telemetry/opentelemetry-ruby-contrib"

# User and Group for app isolation
ARG APP_UID=1000
ARG APP_USER=app
ARG APP_GID=1000
ARG APP_GROUP=app
ARG APP_DIR=/app

ENV SHELL /bin/bash

ARG PACKAGES="\
    autoconf \
    automake \
    bash \
    binutils \
    build-essential \
    ca-certificates \
    coreutils  \
    execline \
    findutils \
    git \
    grep \
    less \
    libstdc++6 \
    libtool \
    libxml2-dev \
    libxslt1-dev \
    default-libmysqlclient-dev \
    libsqlite3-dev \
    openssl \
    libpq-dev \
    pkg-config \
    tzdata \
    util-linux \
    imagemagick \
    "
# Install packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ${PACKAGES} && \
    rm -rf /var/lib/apt/lists/*

# Configure Bundler and PATH
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=20 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG="${BUNDLE_PATH}" \
    BUNDLE_BIN="${BUNDLE_PATH}/bin" \
    BUNDLE_GEMFILE=Gemfile
ENV PATH "${APP_DIR}/bin:${BUNDLE_BIN}:${PATH}"

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem update bundler && \
    gem cleanup

# Add custom app User and Group
RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd --system --no-create-home -d "${APP_DIR}" --uid "${APP_UID}" --gid "${APP_GROUP}" --shell /bin/bash "${APP_USER}"

# Create directories for the app code
RUN mkdir -p "${APP_DIR}" \
    "${APP_DIR}/tmp" && \
    chown -R "${APP_USER}":"${APP_GROUP}" "${APP_DIR}" \
    "${APP_DIR}/tmp" \
    "${BUNDLE_PATH}/"

USER "${APP_USER}"

WORKDIR "${APP_DIR}"

# Commands will be supplied via `docker-compose`
CMD []

# User and Group for app isolation
ARG APP_UID=1000
ARG APP_USER=app
ARG APP_GID=1000
ARG APP_GROUP=app
ARG APP_DIR=/app

# --- SHARED STAGE ---
FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS base-setup

# User and Group for app isolation
ARG APP_UID
ARG APP_GID
ARG APP_DIR

RUN mkdir -p "${APP_DIR}" "${APP_DIR}/tmp"

RUN chown -R "${APP_UID}":"${APP_GID}" "${APP_DIR}" "${APP_DIR}/tmp"


FROM ruby:3.3.12-alpine3.23@sha256:11da101dfad607c6193a921abc815c989bc9f19b43f5f686bbcc7d424298d596 as ruby

# Metadata
LABEL maintainer="open-telemetry/opentelemetry-ruby-contrib"

# User and Group for app isolation
ARG APP_UID
ARG APP_USER
ARG APP_GID
ARG APP_GROUP
ARG APP_DIR

ENV SHELL /bin/bash

ARG PACKAGES="\
    autoconf \
    automake \
    bash \
    binutils \
    build-base \
    coreutils  \
    execline \
    findutils \
    git \
    grep \
    less \
    libstdc++ \
    libtool \
    libxml2-dev \
    libxslt-dev \
    mariadb-dev \
    sqlite-dev \
    openssl \
    postgresql-dev \
    tzdata \
    util-linux \
    imagemagick \
    "
# Install packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${PACKAGES}

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
RUN addgroup -S -g "${APP_GID}" "${APP_GROUP}" && \
    adduser -S -g "${APP_GROUP}" -u "${APP_UID}" "${APP_USER}"

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

# --- Ubuntu stage ---
FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7 AS ubuntu

LABEL maintainer="open-telemetry/opentelemetry-ruby-contrib"

ARG APP_UID
ARG APP_USER
ARG APP_GID
ARG APP_GROUP
ARG APP_DIR

ARG PACKAGES="\
    build-essential \
    curl \
    imagemagick \
    libmysqlclient-dev \
    libpq-dev \
    nodejs \
    tzdata \
"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ${PACKAGES} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Swap the default `ubuntu` user (1000:1000) for our `app` user/group
RUN usermod -l "${APP_USER}" -d "/home/${APP_USER}" -m "ubuntu" && \
    groupmod -n "${APP_GROUP}" "ubuntu"

# Import shared app folder and mise config
COPY --from=base-setup --chown="${APP_USER}:${APP_GROUP}" "${APP_DIR}" "${APP_DIR}"
COPY --chown="${APP_USER}:${APP_GROUP}" mise.toml /app/

# Prime our BUNDLE_PATH permissions for use later
RUN mkdir -p /bundle && chown -R "${APP_USER}:${APP_GROUP}" /bundle

USER "${APP_USER}"

# Configure Bundler and PATH
ENV LANG=C.UTF-8 \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=20 \
    BUNDLE_RETRY=3
ENV BUNDLE_PATH=$GEM_HOME
ENV BUNDLE_APP_CONFIG="${BUNDLE_PATH}" \
    BUNDLE_BIN="${BUNDLE_PATH}/bin" \
    BUNDLE_GEMFILE=Gemfile
ENV PATH="${APP_DIR}/bin:${BUNDLE_BIN}:/home/${APP_USER}/.local/bin:${PATH}"

RUN curl -fsSL https://mise.run | sh && \
    echo 'eval "$(mise activate bash)"' >> ${HOME}/.bashrc

WORKDIR "${APP_DIR}"

RUN mise trust "${APP_DIR}/mise.toml"
RUN mise install

CMD []
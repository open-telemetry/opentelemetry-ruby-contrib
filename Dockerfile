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

# --- Alpine stage ---
FROM ruby:3.3.12-alpine3.23@sha256:11da101dfad607c6193a921abc815c989bc9f19b43f5f686bbcc7d424298d596 AS alpine

ARG APP_UID
ARG APP_USER
ARG APP_GID
ARG APP_GROUP
ARG APP_DIR

# Metadata
LABEL maintainer="open-telemetry/opentelemetry-ruby-contrib"

ENV SHELL="/bin/bash"

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
    nodejs \
    npm \
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
ENV LANG=C.UTF-8
ENV BUNDLE_PATH="${APP_DIR}/vendor/bundle"
ENV PATH="${APP_DIR}/bin:${PATH}"

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem update bundler && \
    gem cleanup

# Add custom app User and Group
RUN addgroup -S -g "${APP_GID}" "${APP_GROUP}" && \
    adduser -S -g "${APP_GROUP}" -u "${APP_UID}" "${APP_USER}"

# Import shared user/group definitions & app folder
COPY --from=base-setup "${APP_DIR}" "${APP_DIR}"

USER "${APP_USER}"

WORKDIR "${APP_DIR}"

# Commands will be supplied via `docker-compose`
CMD []

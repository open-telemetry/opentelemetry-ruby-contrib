FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b as alpine

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
    curl \
    binutils \
    build-base \
    coreutils  \
    execline \
    findutils \
    git \
    grep \
    less \
    libffi-dev \
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
    yaml-dev \
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

ENV TMPDIR=/var/tmp

# Add custom app User and Group
RUN addgroup -S -g "${APP_GID}" "${APP_GROUP}" && \
    adduser -S -g "${APP_GROUP}" -u "${APP_UID}" "${APP_USER}"

RUN mkdir -p "${HOME}/.local/bin"

RUN curl -fsSL https://mise.run  | sh

RUN chmod 755 /root/.local/bin/mise

# Ensure mise is available in PATH during build
ENV PATH="/root/.local/bin:${PATH}"

# Ensure mise loads its environment
RUN echo 'eval "$(mise activate bash)"' >> /root/.bashrc
RUN echo 'eval "$(mise activate sh)"' >> /root/.profile

COPY mise.toml /app/mise.toml

RUN mise trust "${APP_DIR}/mise.toml"

WORKDIR "${APP_DIR}"

RUN mise install

USER "${APP_USER}"

# Commands will be supplied via `docker-compose`
CMD []

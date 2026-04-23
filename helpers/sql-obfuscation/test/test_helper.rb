# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'simplecov'
require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'opentelemetry-helpers-sql-processor'

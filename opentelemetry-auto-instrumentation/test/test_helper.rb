# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rake'
require 'minitest'
require 'minitest/autorun'
require 'opentelemetry-test-helpers'
require 'opentelemetry/resource/detector'
require 'net/http'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-all'

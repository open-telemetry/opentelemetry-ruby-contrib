# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-registry'
# These carry the Metrics and Logs API classes and the internal provider slots
# that Instrumentation::Base reads. Neither defines a top-level provider
# accessor, so requiring them exposes nothing to users of an instrumentation.
require 'opentelemetry-logs-api'
require 'opentelemetry-metrics-api'
require 'opentelemetry/instrumentation/base'

module OpenTelemetry
  # The instrumentation module contains functionality to register and install
  # instrumentation
  module Instrumentation
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Logger gem
    module Logger
      NAME = 'opentelemetry-instrumentation-logger'
    end
  end
end

require_relative 'logger/instrumentation'
require_relative 'logger/version'

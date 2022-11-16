# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Hanami gem
    module Hanami
    end
  end
end

require 'opentelemetry-instrumentation-rack'
require_relative './hanami/instrumentation'
require_relative './hanami/version'

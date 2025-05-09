# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the gRPC gem
    module Grpc
      class Error < StandardError; end
    end
  end
end

require_relative 'grpc/instrumentation'
require_relative 'grpc/version'

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require "opentelemetry"
require "opentelemetry-instrumentation-base"
require "active_support/inflector"

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the gRPC gem
    module Grpc
      class Error < StandardError; end

      module_function

      def client_interceptor
        Interceptors::Client.new
      end
    end
  end
end

require_relative "grpc/instrumentation"
require_relative "grpc/interceptors/client"
require_relative "grpc/version"

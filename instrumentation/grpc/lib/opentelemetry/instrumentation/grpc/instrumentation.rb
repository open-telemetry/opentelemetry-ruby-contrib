# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grpc
      # The Instrumentation class contains logic to detect and install the Grpc instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
        end

        option :allowed_metadata_headers, default: [], validate: :array
        option :peer_service, default: nil, validate: :string

        present do
          defined?(::GRPC)
        end

        private

        def require_dependencies
          require_relative "interceptors/client"
        end
      end
    end
  end
end

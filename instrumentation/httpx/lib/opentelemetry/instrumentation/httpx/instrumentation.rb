# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module HTTPX
      # The Instrumentation class contains logic to detect and install the Http instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        compatible do
          Gem::Version.new(::HTTPX::VERSION) >= Gem::Version.new('0.24.7')
        end

        present do
          defined?(::HTTPX)
        end

        option :peer_service, default: nil, validate: :string

        def patch
          otel_session = ::HTTPX.plugin(Plugin)

          ::HTTPX.send(:remove_const, :Session)
          ::HTTPX.send(:const_set, :Session, otel_session.class)
        end

        def require_dependencies
          require_relative 'plugin'
        end
      end
    end
  end
end

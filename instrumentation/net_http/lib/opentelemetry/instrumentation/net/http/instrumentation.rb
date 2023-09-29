# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module HTTP
        # The Instrumentation class contains logic to detect and install the Net::HTTP
        # instrumentation
        class Instrumentation < OpenTelemetry::Instrumentation::Base
          install do |_config|
            require_dependencies
            patch
          end

          present do
            defined?(::Net::HTTP)
          end

          ## Supported configuration keys for the install config hash:
          #
          # untraced_hosts: if a request's address matches any of the `String`
          #   or `Regexp` in this array, the instrumentation will not record a
          #   `kind = :client` representing the request and will not propagate
          #   context in the request.
          # filter_target: a callable object that takes a path `String` and returns
          #   a `String` to be used as the http.target attribute. The default is to
          #   use the request path as-is.
          option :untraced_hosts, default: [],  validate: :array
          option :filter_target,  default: nil, validate: :callable

          private

          def require_dependencies
            require_relative 'patches/instrumentation'
          end

          def patch
            ::Net::HTTP.prepend(Patches::Instrumentation)
          end
        end
      end
    end
  end
end

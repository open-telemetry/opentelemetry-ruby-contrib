# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry Vitess propagation
    module Vitess
      # Setter for Vitess SQL query propagation
      module SqlQuerySetter
        extend self

        # Set a key and value on the carrier. Assumes the carrier is a string.
        # The key and value will be wrapped in a comment block prepended to the carrier.
        #
        # @param [String] carrier The carrier to set the key and value on
        # @param [String] key The key to set
        # @param [String] value The value to set
        def set(carrier, key, value)
          carrier.gsub!(/\A/, "/*#{key}=#{value}*/")
        rescue FrozenError # rubocop:disable Lint/SuppressedException
        end
      end

      # Propagates context using Vitess header format:
      # https://vitess.io/docs/16.0/user-guides/configuration-advanced/tracing/#instrumenting-queries
      class SqlQueryPropagator
        VT_SPAN_CONTEXT = 'VT_SPAN_CONTEXT'
        FIELDS = [VT_SPAN_CONTEXT].freeze

        private_constant :VT_SPAN_CONTEXT, :FIELDS

        def initialize
          @jaeger = OpenTelemetry::Propagator::Jaeger.text_map_propagator
        end

        # No-op extractor.
        def extract(carrier, context: Context.current, getter: nil)
          context
        end

        # @param [Object] carrier to update with context.
        # @param [optional Context] context The active Context.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        def inject(carrier, context: Context.current, setter: SqlQuerySetter)
          span_context = Trace.current_span(context).context
          return unless span_context.valid?

          jaeger = {}
          @jaeger.inject(jaeger, context: context)
          encoded = Base64.strict_encode64(jaeger.to_json)
          setter.set(carrier, VT_SPAN_CONTEXT, encoded)

          nil
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          FIELDS
        end
      end
    end
  end
end

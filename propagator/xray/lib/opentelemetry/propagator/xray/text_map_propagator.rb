# frozen_string_literal: true

# Copyright OpenTelemetry Authors
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
    # Namespace for OpenTelemetry XRay propagation
    module XRay
      # Propagates context in carriers in the xray single header format
      class TextMapPropagator
        XRAY_CONTEXT_KEY = 'X-Amzn-Trace-Id'
        SAMPLED_VALUES = %w[1 d].freeze
        FIELDS = [XRAY_CONTEXT_KEY].freeze

        # Header parsing constants
        KV_PAIR_DELIMITER = ';'
        KEY_AND_VALUE_DELIMITER = '='
        TRACE_ID_KEY = 'Root'
        PARENT_ID_KEY = 'Parent'
        SAMPLED_FLAG_KEY = 'Sampled'
        TRACE_ID_LENGTH = 35
        SPAN_ID_LENGTH = 16
        VALID_SAMPLED_VALUES = %w[0 1 d].freeze

        private_constant :XRAY_CONTEXT_KEY, :SAMPLED_VALUES, :FIELDS,
                         :KV_PAIR_DELIMITER, :KEY_AND_VALUE_DELIMITER,
                         :TRACE_ID_KEY, :PARENT_ID_KEY, :SAMPLED_FLAG_KEY,
                         :TRACE_ID_LENGTH, :SPAN_ID_LENGTH, :VALID_SAMPLED_VALUES

        # Extract trace context from the supplied carrier.
        # If extraction fails, the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [optional Context] context Context to be updated with the trace context
        #   extracted from the carrier. Defaults to +Context.current+.
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   text map getter will be used.
        #
        # @return [Context] context updated with extracted baggage, or the original context
        #   if extraction fails
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          header = getter.get(carrier, XRAY_CONTEXT_KEY)
          return context unless header

          match = parse_header(header)
          return context unless match

          span_context = Trace::SpanContext.new(
            trace_id: to_trace_id(match['trace_id']),
            span_id: to_span_id(match['span_id']),
            trace_flags: to_trace_flags(match['sampling_state']),
            tracestate: to_trace_state(match['trace_state']),
            remote: true
          )

          span = OpenTelemetry::Trace.non_recording_span(span_context)
          context = XRay.context_with_debug(context) if match['sampling_state'] == 'd'
          Trace.context_with_span(span, parent_context: context)
        rescue OpenTelemetry::Error
          context
        end

        # Inject trace context into the supplied carrier.
        #
        # @param [Carrier] carrier The mutable carrier to inject trace context into
        # @param [Context] context The context to read trace context from
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   text map setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          span_context = Trace.current_span(context).context
          return unless span_context.valid?

          sampling_state = if XRay.debug?(context)
                             'd'
                           elsif span_context.trace_flags.sampled?
                             '1'
                           else
                             '0'
                           end

          ot_trace_id = span_context.hex_trace_id
          xray_trace_id = "1-#{ot_trace_id[0..7]}-#{ot_trace_id[8..ot_trace_id.length]}"
          parent_id = span_context.hex_span_id

          xray_value = "Root=#{xray_trace_id};Parent=#{parent_id};Sampled=#{sampling_state}"

          setter.set(carrier, XRAY_CONTEXT_KEY, xray_value)
          nil
        end

        private

        def parse_header(header)
          trace_id = nil
          span_id = nil
          sampling_state = nil
          trace_state_parts = []

          header.split(KV_PAIR_DELIMITER).each do |pair|
            # Split only on first '=' to handle values that might contain '='
            key, value = pair.split(KEY_AND_VALUE_DELIMITER, 2)
            next unless key && value

            case key
            when TRACE_ID_KEY
              trace_id = value if valid_trace_id?(value)
            when PARENT_ID_KEY
              span_id = value if valid_span_id?(value)
            when SAMPLED_FLAG_KEY
              sampling_state = value if valid_sampling_state?(value)
            when 'Self'
              # Ignore Self field added by load balancers
              next
            else
              # Collect other fields as potential tracestate
              trace_state_parts << pair
            end
          end

          return nil unless trace_id && span_id

          {
            'trace_id' => trace_id,
            'span_id' => span_id,
            'sampling_state' => sampling_state,
            'trace_state' => trace_state_parts.empty? ? nil : trace_state_parts.join(KV_PAIR_DELIMITER)
          }
        end

        def valid_trace_id?(value)
          return false unless value.length == TRACE_ID_LENGTH
          return false unless value.start_with?('1-')
          return false unless value[10] == '-'

          true
        end

        def valid_span_id?(value)
          value.length == SPAN_ID_LENGTH && value.match?(/\A[a-f0-9]+\z/)
        end

        def valid_sampling_state?(value)
          VALID_SAMPLED_VALUES.include?(value)
        end

        # Convert an id from a hex encoded string to byte array. Assumes the input id has already been
        # validated to be 35 characters in length.
        def to_trace_id(hex_id)
          Array(hex_id[2..9] + hex_id[11..hex_id.length]).pack('H*')
        end

        # Convert an id from a hex encoded string to byte array.
        def to_span_id(hex_id)
          Array(hex_id).pack('H*')
        end

        def to_trace_flags(sampling_state)
          if SAMPLED_VALUES.include?(sampling_state)
            Trace::TraceFlags::SAMPLED
          else
            Trace::TraceFlags::DEFAULT
          end
        end

        def to_trace_state(trace_state)
          return nil unless trace_state

          Trace::Tracestate.from_string(trace_state.tr(';', ','))
        end
      end
    end
  end
end

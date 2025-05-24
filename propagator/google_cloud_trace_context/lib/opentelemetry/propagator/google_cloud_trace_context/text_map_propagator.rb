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
    # Namespace for OpenTelemetry GoogleCloudTraceContext propagation
    module GoogleCloudTraceContext
      # Provides a class for decoding and encoding x-cloud-trace-context header to/from into trace components
      class CloudTraceContext
        CLOUD_TRACE_CONTEXT_REGEX = %r{\A(?<trace_id>[a-f0-9]{32})\/(?<span_id>[0-9]+)(?:;o=(?<options>[01]))?\Z}i

        private_constant :CLOUD_TRACE_CONTEXT_REGEX

        class << self
          # Creates a new {CloudTraceContext} from a supplied {Trace::SpanContext}
          # @param [SpanContext] ctx The span context
          # @return [CloudTraceContext] a trace parent
          def from_span_context(ctx)
            new(trace_id: ctx.trace_id, span_id: ctx.span_id, flags: ctx.trace_flags)
          end

          # Deserializes the {CloudTraceContext} from the string representation
          # @param [String] string The serialized trace parent
          # @return [CloudTraceContext, nil] a trace_parent or nil if malformed
          def from_string(string)
            matches = CLOUD_TRACE_CONTEXT_REGEX.match(string)
            return unless matches

            trace_id = Array(matches[:trace_id].downcase).pack('H*')
            span_id = Array(matches[:span_id].to_i.to_s(16)).pack('H*')
            flags = matches[:options] == '1' ? Trace::TraceFlags::SAMPLED : Trace::TraceFlags::DEFAULT

            new(trace_id: trace_id, span_id: span_id, flags: flags)
          end
        end

        attr_reader :trace_id, :span_id, :flags

        private_class_method :new

        # converts this object into a string according to the w3c spec
        # @return [String] the serialized trace_parent
        def to_s
          "#{trace_id.unpack1('H*')}/#{span_id.unpack1('H*').to_i(16)};o=#{flags.sampled? ? '1' : '0'}"
        end

        private

        def initialize(trace_id: nil, span_id: nil, flags: Trace::TraceFlags::DEFAULT)
          @trace_id = trace_id
          @span_id = span_id
          @flags = flags
        end
      end

      # Propagates context using GoogleCloudTraceContext header format
      class TextMapPropagator
        CLOUD_TRACE_CONTEXT_KEY = 'x-cloud-trace-context'
        FIELDS = [CLOUD_TRACE_CONTEXT_KEY].freeze

        private_constant :CLOUD_TRACE_CONTEXT_KEY, :FIELDS

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

          setter.set(carrier, CLOUD_TRACE_CONTEXT_KEY, CloudTraceContext.from_span_context(span_context).to_s)
          nil
        end

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
          trace_parent_value = getter.get(carrier, CLOUD_TRACE_CONTEXT_KEY)
          return context unless trace_parent_value

          cloud_trace_context = CloudTraceContext.from_string(trace_parent_value)
          return context unless cloud_trace_context

          span_context = Trace::SpanContext.new(trace_id: cloud_trace_context.trace_id,
                                                span_id: cloud_trace_context.span_id,
                                                trace_flags: cloud_trace_context.flags,
                                                remote: true)
          span = Trace.non_recording_span(span_context)
          Trace.context_with_span(span, parent_context: context)
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

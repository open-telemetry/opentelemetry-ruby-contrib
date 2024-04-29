# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'
require 'opentelemetry-sdk'

module OpenTelemetry
  module Processor
    module Baggage
      # The BaggageSpanProcessor reads key/values stored in Baggage in the
      # starting span's parent context and adds them as attributes to the span.
      #
      # Keys and values added to Baggage will appear on all subsequent child spans
      # for a trace within this service *and* will be propagated to external services
      # via propagation headers. If the external services also have a Baggage span
      # processor, the keys and values will appear in those child spans as well.
      #
      # ⚠️
      # To repeat: a consequence of adding data to Baggage is that the keys and
      # values will appear in all outgoing HTTP headers from the application.
      # Do not put sensitive information in Baggage.
      # ⚠️
      #
      # @example
      #   OpenTelemetry::SDK.configure do |c|
      #     # Add the BaggageSpanProcessor to the collection of span processors
      #     c.add_span_processor(OpenTelemetry::Processor::Baggage::BaggageSpanProcessor.new)
      #
      #     # Because the span processor list is no longer empty, the SDK will not use the
      #     # values in OTEL_TRACES_EXPORTER to instantiate exporters.
      #     # You'll need to declare your own here in the configure block.
      #     #
      #     # These lines setup the default: a batching OTLP exporter.
      #     c.add_span_processor(
      #       # these constructors without arguments will pull config from the environment
      #       OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      #         OpenTelemetry::Exporter::OTLP::Exporter.new()
      #       )
      #     )
      #   end
      class BaggageSpanProcessor < OpenTelemetry::SDK::Trace::SpanProcessor
        # Called when a `Span` is started, adds Baggage keys/values to the span as attributes.
        #
        # @param [Span] span the `Span` that just started, expected to conform
        #  to the concrete `Span` interface from the SDK and respond to :add_attributes.
        # @param [Context] parent_context the parent `Context` of the newly
        #  started span.
        def on_start(span, parent_context)
          return unless span.respond_to?(:add_attributes) && parent_context.is_a?(::OpenTelemetry::Context)

          span.add_attributes(::OpenTelemetry::Baggage.values(context: parent_context))
        end

        # Called when a Span is ended, does nothing.
        #
        # NO-OP method to satisfy the SpanProcessor duck type.
        #
        # @param [Span] span the {OpenTelemetry::Trace::Span} that just ended.
        def on_finish(span); end

        # Always successful; this processor does not maintain any state to flush.
        #
        # NO-OP method to satisfy the `SpanProcessor` duck type.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] 0 for success and there is nothing to flush so always successful.
        def force_flush(timeout: nil)
          0
        end

        # Always successful; this processor does not maintain any state to clean up or processes to close on shutdown.
        #
        # NO-OP method to satisfy the `SpanProcessor` duck type.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] 0 for success and there is nothing to stop so always successful.
        def shutdown(timeout: nil)
          0
        end
      end
    end
  end
end

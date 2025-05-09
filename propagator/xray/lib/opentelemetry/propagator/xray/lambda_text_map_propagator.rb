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
      # Implementation of AWS X-Ray Trace Header propagation with special handling for
      # Lambda's _X_AMZN_TRACE_ID environment variable
      class LambdaTextMapPropagator < TextMapPropagator
        AWS_TRACE_HEADER_ENV_KEY = '_X_AMZN_TRACE_ID'

        # Extract trace context from the supplied carrier or from Lambda environment variable
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
          # Check if the original input context already has a valid span
          span_context = Trace.current_span(context).context
          # If original context is valid, just return it - do not extract from carrier
          return context if span_context.valid?

          # First try to extract from the carrier using the standard X-Ray propagator
          xray_context = super

          # Check if we successfully extracted a context from the carrier
          span_context = Trace.current_span(xray_context).context
          return xray_context if span_context.valid?

          # If not, check for the Lambda environment variable
          trace_header = ENV.fetch(AWS_TRACE_HEADER_ENV_KEY, nil)
          return xray_context unless trace_header

          # Create a carrier with the trace header and extract from it
          env_carrier = { XRAY_CONTEXT_KEY => trace_header }
          super(env_carrier, context: xray_context, getter: getter)
        rescue OpenTelemetry::Error
          context
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/semconv/http'
require 'opentelemetry/semconv/incubating/code'

module OpenTelemetry
  module Instrumentation
    module Rage
      module Handlers
        # The class updates the name of the Rack span, adds relevant attributes, and records
        # exceptions if any occur during the processing of a controller action.
        class Request < ::Rage::Telemetry::Handler
          handle 'controller.action.process', with: :enrich_request_span

          # @param controller [RageController::API] the controller processing the request
          # @param request [Rage::Request] the request being processed
          def self.enrich_request_span(controller:, request:)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return yield unless span.recording?

            http_route = request.route_uri_pattern
            span.name = "#{request.method} #{http_route}"

            attributes = {
              SemConv::HTTP::HTTP_ROUTE => http_route,
              SemConv::Incubating::CODE::CODE_FUNCTION_NAME => "#{controller.class}##{controller.action_name}"
            }
            span.add_attributes(attributes)

            result = yield
            return unless result.error?

            span.record_exception(result.exception)
            span.status = OpenTelemetry::Trace::Status.error
          end
        end
      end
    end
  end
end

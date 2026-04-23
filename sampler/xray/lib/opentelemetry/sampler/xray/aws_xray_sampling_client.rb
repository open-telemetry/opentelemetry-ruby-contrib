# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'net/http'
require 'json'
require 'uri'

module OpenTelemetry
  module Sampler
    module XRay
      # AWSXRaySamplingClient is responsible for making '/GetSamplingRules' and '/SamplingTargets' calls
      # to AWS X-Ray to retrieve Sampling Rules and Sampling Targets respectively
      class AWSXRaySamplingClient
        def initialize(endpoint)
          @endpoint = endpoint
          @host, @port = parse_endpoint(@endpoint)

          @sampling_rules_url = URI::HTTP.build(host: @host, path: '/GetSamplingRules', port: @port)
          @sampling_targets_url = URI::HTTP.build(host: @host, path: '/SamplingTargets', port: @port)
          @request_headers = { 'content-type': 'application/json' }
        end

        def fetch_sampling_rules
          begin
            OpenTelemetry::Common::Utilities.untraced do
              return Net::HTTP.post(@sampling_rules_url, '{}', @request_headers)
            end
          rescue StandardError => e
            OpenTelemetry.logger.debug("Error occurred when fetching Sampling Rules: #{e}")
          end
          nil
        end

        def fetch_sampling_targets(request_body)
          begin
            OpenTelemetry::Common::Utilities.untraced do
              return Net::HTTP.post(@sampling_targets_url, request_body.to_json, @request_headers)
            end
          rescue StandardError => e
            OpenTelemetry.logger.debug("Error occurred when fetching Sampling Targets: #{e}")
          end
          nil
        end

        private

        def parse_endpoint(endpoint)
          host, port = endpoint.split(':')
          [host, port.to_i]
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: "Invalid endpoint: #{endpoint}")
          raise e
        end
      end
    end
  end
end

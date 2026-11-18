# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/semconv/incubating/peer'
require 'opentelemetry/semconv/network'
require 'opentelemetry/semconv/server'
require_relative 'attribute_mapper'

module OpenTelemetry
  module Instrumentation
    module Net
      module LDAP
        # instrumentation service for ldap
        class InstrumentationService
          def initialize(args = {})
            @host = args[:host]
            @port = args[:port]
            @hosts = args[:hosts]
            @auth = args[:auth]
            @base = args[:base]
            @encryption = args[:encryption]
          end

          # Wraps a Net::LDAP operation in a span and annotates it with the response.
          # Implements the ActiveSupport::Notifications-compatible service interface that Net::LDAP expects.
          #
          # @param event [String] the event name, e.g. +search.net_ldap+
          # @param payload [Hash] the event payload
          # @yieldparam payload [Hash] the event payload
          # @return [Object] the value returned by the block
          def instrument(event, payload)
            operation_type, span_kind = event.split('.').then { |s| [s.first, s.last == 'net_ldap_connection' ? :internal : :client] }

            attributes = {
              'ldap.auth.method' => auth[:method].to_s,
              'ldap.auth.username' => auth[:username].to_s,
              'ldap.operation.type' => operation_type,
              'ldap.request.message' => begin
                raw = payload.to_json
                raw.scrub == raw ? raw : nil
              rescue JSON::GeneratorError
                nil
              end,
              'ldap.tree.base' => base,
              OpenTelemetry::SemConv::SERVER::SERVER_ADDRESS => host || hosts,
              OpenTelemetry::SemConv::SERVER::SERVER_PORT => port,
              OpenTelemetry::SemConv::Incubating::PEER::PEER_SERVICE => instrumentation_config[:peer_service],
              OpenTelemetry::SemConv::NETWORK::NETWORK_TRANSPORT => 'tcp',
              OpenTelemetry::SemConv::NETWORK::NETWORK_PROTOCOL_NAME => 'ldap',
              OpenTelemetry::SemConv::NETWORK::NETWORK_PROTOCOL_VERSION => ::Net::LDAP::Connection::LdapVersion
            }

            attributes.compact!

            # Top-level operations (bind, search, add, ...) return true/false/nil/results rather
            # than a PDU. `open` returns whatever the user's block returns, so it says nothing
            # about the outcome.
            operation = span_kind == :client && operation_type != 'open'

            tracer.in_span(
              "LDAP #{operation_type}",
              attributes: AttributeMapper.map(attributes),
              kind: span_kind
            ) do |span|
              if instrumentation_config[:enable_internal_instrumentation] == false
                OpenTelemetry::Common::Utilities.untraced do
                  yield(payload).tap do |response|
                    annotate_span_with_response(span, response, operation: operation)
                  end
                end
              else
                yield(payload).tap do |response|
                  annotate_span_with_response(span, response, operation: operation)
                end
              end
            end
          end

          private

          attr_reader :host, :port, :hosts, :auth, :base, :encryption

          def tracer
            LDAP::Instrumentation.instance.tracer
          end

          def instrumentation_config
            LDAP::Instrumentation.instance.config
          end

          def annotate_span_with_response(span, response, operation:)
            message = ''
            error_message = ''

            if response.respond_to?(:result_code)
              status_code = response.result_code
              message = ::Net::LDAP.result2string(status_code).to_s
              error_message = response.respond_to?(:error_message) ? response.error_message.to_s : ''
            elsif operation
              # A falsy return means the operation failed, but the result code is not available here.
              return span.status = OpenTelemetry::Trace::Status.error unless response

              status_code = ::Net::LDAP::ResultCodeSuccess
            else
              return
            end

            attributes = { 'ldap.response.status_code' => status_code }
            attributes['ldap.response.message'] = message unless message.empty?
            attributes['ldap.error.message'] = error_message unless error_message.empty?
            span.add_attributes(attributes)

            return if ::Net::LDAP::ResultCodesNonError.include?(status_code)

            span.status = OpenTelemetry::Trace::Status.error
          end
        end
      end
    end
  end
end

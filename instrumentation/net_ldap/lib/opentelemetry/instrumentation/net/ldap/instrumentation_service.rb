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

          def instrument(event, payload)
            attributes = {
              'ldap.auth.method' => auth[:method].to_s,
              'ldap.auth.username' => auth[:username].to_s,
              'ldap.tree.base' => base,
              'ldap.request.message' => payload.to_json,
              OpenTelemetry::SemConv::SERVER::SERVER_ADDRESS => host || hosts,
              OpenTelemetry::SemConv::SERVER::SERVER_PORT => port,
              OpenTelemetry::SemConv::Incubating::PEER::PEER_SERVICE => instrumentation_config[:peer_service],
              OpenTelemetry::SemConv::NETWORK::NETWORK_TRANSPORT => 'tcp',
              OpenTelemetry::SemConv::NETWORK::NETWORK_PROTOCOL_NAME => 'ldap',
              OpenTelemetry::SemConv::NETWORK::NETWORK_PROTOCOL_VERSION => ::Net::LDAP::Connection::LdapVersion
            }
            attributes.delete_if { |_key, value| value.nil? }

            span_name, span_kind = event.split('.').then { |s| [s.first, s.last == 'net_ldap_connection' ? :internal : :client] }
            tracer.in_span(
              "LDAP #{span_name}",
              attributes: AttributeMapper.map(attributes),
              kind: span_kind
            ) do |span|
              yield(payload).tap do |response|
                annotate_span_with_response(span, response) if response
              end
            rescue ::Net::LDAP::Error => e
              span.add_attributes({
                                    'error.type' => e.class.to_s,
                                    'error.message' => e.message.to_s
                                  })
              span.status = OpenTelemetry::Trace::Status.error
              raise e
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

          def annotate_span_with_response(span, response)
            status_code = ::Net::LDAP::ResultCodeSuccess
            message = ''
            error_message = ''

            if response.is_a?(::Net::LDAP::PDU)
              status_code ||= response.result_code
              error_message = response.error_message.to_s
              message = ::Net::LDAP.result2string(status_code)
            end
            attributes = {
              'ldap.response.status_code' => status_code
            }
            attributes['ldap.response.message'] = message unless message.empty?
            attributes['error.message'] = error_message unless error_message.empty?
            span.add_attributes(attributes)

            return if ::Net::LDAP::ResultCodesNonError.include?(status_code)

            span.status = OpenTelemetry::Trace::Status.error
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-helpers-mysql'
require 'opentelemetry-helpers-sql-obfuscation'

module OpenTelemetry
  module Instrumentation
    module Trilogy
      module Patches
        # Module to prepend to Trilogy for instrumentation
        module Client
          def initialize(options = {})
            @connection_options = options # This is normally done by Trilogy#initialize

            tracer.in_span(
              'connect',
              attributes: client_attributes.merge!(OpenTelemetry::Instrumentation::Trilogy.attributes),
              kind: :client
            ) do
              super
            end
          end

          def ping(...)
            tracer.in_span(
              'ping',
              attributes: client_attributes.merge!(OpenTelemetry::Instrumentation::Trilogy.attributes),
              kind: :client
            ) do
              super
            end
          end

          def query(sql)
            tracer.in_span(
              OpenTelemetry::Helpers::MySQL.database_span_name(
                sql,
                OpenTelemetry::Instrumentation::Trilogy.attributes[
                  OpenTelemetry::SemanticConventions::Trace::DB_OPERATION
                ],
                database_name,
                config
              ),
              attributes: client_attributes(sql).merge!(
                OpenTelemetry::Instrumentation::Trilogy.attributes
              ),
              kind: :client
            ) do |_span, context|
              if propagator && sql.frozen?
                sql = +sql
                propagator.inject(sql, context: context)
                sql.freeze
              elsif propagator
                propagator.inject(sql, context: context)
              end

              super
            end
          end

          private

          def client_attributes(sql = nil)
            attributes = {
              ::OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM => 'mysql',
              ::OpenTelemetry::SemanticConventions::Trace::NET_PEER_NAME => connection_options&.fetch(:host, 'unknown sock') || 'unknown sock'
            }

            attributes[::OpenTelemetry::SemanticConventions::Trace::DB_NAME] = database_name if database_name
            attributes[::OpenTelemetry::SemanticConventions::Trace::DB_USER] = database_user if database_user
            attributes[::OpenTelemetry::SemanticConventions::Trace::PEER_SERVICE] = config[:peer_service] unless config[:peer_service].nil?
            attributes['db.instance.id'] = @connected_host unless @connected_host.nil?

            if sql
              case config[:db_statement]
              when :obfuscate
                attributes[::OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT] =
                  OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(sql, obfuscation_limit: config[:obfuscation_limit], adapter: :mysql)
              when :include
                attributes[::OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT] = sql
              end
            end

            attributes
          end

          def database_name
            connection_options[:database]
          end

          def database_user
            connection_options[:username]
          end

          def tracer
            Trilogy::Instrumentation.instance.tracer
          end

          def config
            Trilogy::Instrumentation.instance.config
          end

          def propagator
            Trilogy::Instrumentation.instance.propagator
          end
        end
      end
    end
  end
end

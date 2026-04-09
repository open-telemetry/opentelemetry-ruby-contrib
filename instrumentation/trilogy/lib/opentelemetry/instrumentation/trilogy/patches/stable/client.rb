# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-helpers-mysql'
require 'opentelemetry-helpers-sql-processor'

module OpenTelemetry
  module Instrumentation
    module Trilogy
      module Patches
        module Stable
          # Module to prepend to Trilogy for instrumentation (stable semantic conventions)
          module Client
            def initialize(options = {})
              @connection_options = options # This is normally done by Trilogy#initialize
              @_otel_database_name = connection_options&.dig(:database)
              @_otel_base_attributes = _build_otel_base_attributes.freeze

              tracer.in_span(
                'connect',
                attributes: client_attributes.merge!(OpenTelemetry::Instrumentation::Trilogy.attributes),
                kind: :client,
                record_exception: config[:record_exception]
              ) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def ping(...)
              tracer.in_span(
                'ping',
                attributes: client_attributes.merge!(OpenTelemetry::Instrumentation::Trilogy.attributes),
                kind: :client,
                record_exception: config[:record_exception]
              ) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def query(sql)
              context_attributes = OpenTelemetry::Instrumentation::Trilogy.attributes

              tracer.in_span(
                OpenTelemetry::Helpers::MySQL.stable_database_span_name(
                  context_attributes['db.operation.name'],
                  @_otel_database_name
                ),
                attributes: client_attributes(sql).merge!(context_attributes),
                kind: :client,
                record_exception: config[:record_exception]
              ) do |span, context|
                if propagator && sql.frozen?
                  sql = +sql
                  propagator.inject(sql, context: context)
                  sql.freeze
                elsif propagator
                  propagator.inject(sql, context: context)
                end

                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            private

            def _build_otel_base_attributes
              mysql_host = connection_options&.fetch(:host, nil) || 'unknown sock'
              mysql_port = connection_options&.dig(:port)

              attributes = {
                'db.system.name' => 'mysql',
                'server.address' => mysql_host
              }

              attributes['server.port'] = mysql_port if mysql_port

              attributes['db.namespace'] = @_otel_database_name if @_otel_database_name
              attributes
            end

            def client_attributes(sql = nil)
              attributes = @_otel_base_attributes.dup

              if sql
                case config[:db_statement]
                when :obfuscate
                  attributes['db.query.text'] =
                    OpenTelemetry::Helpers::SqlProcessor.obfuscate_sql(sql, obfuscation_limit: config[:obfuscation_limit], adapter: :mysql)
                when :include
                  attributes['db.query.text'] = sql
                end
              end

              attributes
            end

            def set_error_attributes(span, error)
              span.set_attribute('error.type', error.class.name)
              span.set_attribute('db.response.status_code', error.error_code.to_s) if error.error_code
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
end

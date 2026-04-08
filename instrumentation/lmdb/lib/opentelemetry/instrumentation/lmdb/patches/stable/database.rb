# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module LMDB
      module Patches
        module Stable
          # Module to prepend to LMDB::Database for instrumentation
          module Database
            STATEMENT_MAX_LENGTH = 500

            def get(key)
              statement = formatted_statement('GET', "GET #{key}")
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'GET'
              }
              attributes['db.query.text'] = statement if config[:db_statement] == :include

              tracer.in_span("GET #{key}", attributes: attributes, kind: :client) do
                super
              end
            end

            def delete(key, value = nil)
              statement = formatted_statement('DELETE', "DELETE #{key} #{value}".strip)
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'DELETE'
              }
              attributes['db.query.text'] = statement if config[:db_statement] == :include

              tracer.in_span("DELETE #{key}", attributes: attributes, kind: :client) do
                super
              end
            end

            def put(key, value)
              statement = formatted_statement('PUT', "PUT #{key} #{value}")
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'PUT'
              }
              attributes['db.query.text'] = statement if config[:db_statement] == :include

              tracer.in_span("PUT #{key}", attributes: attributes, kind: :client) do
                super
              end
            end

            def clear
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'CLEAR'
              }
              attributes['db.query.text'] = 'CLEAR' if config[:db_statement] == :include

              tracer.in_span('CLEAR', attributes: attributes, kind: :client) do
                super
              end
            end

            private

            def formatted_statement(operation, statement)
              statement = OpenTelemetry::Common::Utilities.truncate(statement, STATEMENT_MAX_LENGTH)
              OpenTelemetry::Common::Utilities.utf8_encode(statement)
            rescue StandardError => e
              OpenTelemetry.logger.debug("non formattable LMDB statement #{statement}: #{e}")
              "#{operation} BLOB (OMITTED)"
            end

            def config
              LMDB::Instrumentation.instance.config
            end

            def tracer
              LMDB::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end

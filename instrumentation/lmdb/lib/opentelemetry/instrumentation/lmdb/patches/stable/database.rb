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
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'GET',
                'db.namespace' => env.path
              }
              attributes['db.query.text'] = formatted_statement('GET', key) unless config[:db_statement] == :omit

              tracer.in_span('GET', attributes: attributes, kind: :internal) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def delete(key, value = nil)
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'DELETE',
                'db.namespace' => env.path
              }
              attributes['db.query.text'] = formatted_statement('DELETE', key, value) unless config[:db_statement] == :omit

              tracer.in_span('DELETE', attributes: attributes, kind: :internal) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def put(key, value)
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'PUT',
                'db.namespace' => env.path
              }
              attributes['db.query.text'] = formatted_statement('PUT', key, value) unless config[:db_statement] == :omit

              tracer.in_span('PUT', attributes: attributes, kind: :internal) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def clear
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'CLEAR',
                'db.namespace' => env.path
              }
              attributes['db.query.text'] = formatted_statement('CLEAR') unless config[:db_statement] == :omit

              tracer.in_span('CLEAR', attributes: attributes, kind: :internal) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            private

            def formatted_statement(operation, *args)
              statement = case config[:db_statement]
                          when :obfuscate
                            operation + (' ?' * args.compact.length)
                          when :include
                            [operation, *args.compact].join(' ')
                          end
              return unless statement

              statement = OpenTelemetry::Common::Utilities.truncate(statement, STATEMENT_MAX_LENGTH)
              OpenTelemetry::Common::Utilities.utf8_encode(statement, binary: true)
            rescue StandardError => e
              OpenTelemetry.logger.debug("non formattable LMDB statement for #{operation}: #{e}")
              "#{operation} BLOB (OMITTED)"
            end

            def set_error_attributes(span, error)
              span.set_attribute('error.type', error.class.name)
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

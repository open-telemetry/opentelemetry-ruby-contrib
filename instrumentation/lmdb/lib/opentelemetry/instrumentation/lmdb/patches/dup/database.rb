# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module LMDB
      module Patches
        module Dup
          # Module to prepend to LMDB::Database for instrumentation
          module Database
            STATEMENT_MAX_LENGTH = 500

            def get(key)
                attributes = {
                'db.system' => 'lmdb',
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'GET',
                'db.namespace' => env.path
              }
              unless config[:db_statement] == :omit
                attributes['db.statement'] = raw_statement('GET', key)
                attributes['db.query.text'] = formatted_statement('GET', key)
              end
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              tracer.in_span("GET #{key}", attributes: attributes, kind: :client) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def delete(key, value = nil)
              attributes = {
                'db.system' => 'lmdb',
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'DELETE',
                'db.namespace' => env.path
              }
              unless config[:db_statement] == :omit
                attributes['db.statement'] = raw_statement('DELETE', key, value)
                attributes['db.query.text'] = formatted_statement('DELETE', key, value)
              end
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              tracer.in_span("DELETE #{key}", attributes: attributes, kind: :client) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def put(key, value)
              attributes = {
                'db.system' => 'lmdb',
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'PUT',
                'db.namespace' => env.path
              }
              unless config[:db_statement] == :omit
                attributes['db.statement'] = raw_statement('PUT', key, value)
                attributes['db.query.text'] = formatted_statement('PUT', key, value)
              end
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              tracer.in_span("PUT #{key}", attributes: attributes, kind: :client) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            def clear
              attributes = {
                'db.system' => 'lmdb',
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'CLEAR',
                'db.namespace' => env.path
              }
              unless config[:db_statement] == :omit
                attributes['db.statement'] = raw_statement('CLEAR')
                attributes['db.query.text'] = formatted_statement('CLEAR')
              end
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              tracer.in_span('CLEAR', attributes: attributes, kind: :client) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            private

            # The old conventions never sanitized db.statement, so it keeps carrying the
            # key and any value verbatim regardless of :obfuscate. Users only get
            # sanitized query text once they move from database/dup to database.
            def raw_statement(operation, *args)
              truncate_and_encode([operation, *args.compact].join(' '), operation)
            end

            def formatted_statement(operation, *args)
              case config[:db_statement]
              when :obfuscate
                truncate_and_encode(operation + (' ?' * args.compact.length), operation)
              when :include
                raw_statement(operation, *args)
              end
            end

            def truncate_and_encode(statement, operation)
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

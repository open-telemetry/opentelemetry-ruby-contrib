# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../constants'
require_relative '../lru_cache'

module OpenTelemetry
  module Instrumentation
    module PG
      module Patches
        # Module to prepend to PG::Connection for instrumentation
        module Connection # rubocop:disable Metrics/ModuleLength
          PG::Constants::EXEC_ISH_METHODS.each do |method|
            define_method method do |*args, &block|
              span_name, attrs = span_attrs(:query, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
                if block
                  block.call(super(*args))
                else
                  super(*args)
                end
              end
            end
          end

          PG::Constants::PREPARE_ISH_METHODS.each do |method|
            define_method method do |*args|
              span_name, attrs = span_attrs(:prepare, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
                super(*args)
              end
            end
          end

          PG::Constants::EXEC_PREPARED_ISH_METHODS.each do |method|
            define_method method do |*args, &block|
              span_name, attrs = span_attrs(:execute, *args)
              tracer.in_span(span_name, attributes: attrs, kind: :client) do
                if block
                  block.call(super(*args))
                else
                  super(*args)
                end
              end
            end
          end

          private

          def tracer
            PG::Instrumentation.instance.tracer
          end

          def config
            PG::Instrumentation.instance.config
          end

          def lru_cache
            # When SQL is being sanitized, we know that this cache will
            # never be more than 50 entries * 2000 characters (so, presumably
            # 100k bytes - or 97k). When not sanitizing SQL, then this cache
            # could grow much larger - but the small cache size should otherwise
            # help contain memory growth. The intended use here is to cache
            # prepared SQL statements, so that we can attach a reasonable
            # `db.sql.statement` value to spans when those prepared statements
            # are executed later on.
            @lru_cache ||= LruCache.new(50)
          end

          # Rubocop is complaining about 19.31/18 for Metrics/AbcSize.
          # But, getting that metric in line would force us over the
          # module size limit! We can't win here unless we want to start
          # abstracting things into a million pieces.
          def span_attrs(kind, *args)
            if kind == :query
              operation = extract_operation(args[0])
              sql = obfuscate_sql(args[0]).to_s
            else
              statement_name = args[0]

              if kind == :prepare
                sql = obfuscate_sql(args[1]).to_s
                lru_cache[statement_name] = sql
                operation = 'PREPARE'
              else
                sql = lru_cache[statement_name]
                operation = 'EXECUTE'
              end
            end

            attrs = { 'db.operation' => validated_operation(operation), 'db.postgresql.prepared_statement_name' => statement_name }
            attrs['db.statement'] = sql unless config[:db_statement] == :omit
            attrs.merge!(OpenTelemetry::Instrumentation::PG.attributes)
            attrs.compact!

            [span_name(operation), client_attributes.merge(attrs)]
          end

          def extract_operation(sql)
            # From: https://github.com/open-telemetry/opentelemetry-js-contrib/blob/9244a08a8d014afe26b82b91cf86e407c2599d73/plugins/node/opentelemetry-instrumentation-pg/src/utils.ts#L35
            sql.to_s.split[0].to_s.upcase
          end

          def span_name(operation)
            [validated_operation(operation), db].compact.join(' ')
          end

          def validated_operation(operation)
            operation if PG::Constants::SQL_COMMANDS.include?(operation)
          end

          def obfuscate_sql(sql)
            return sql unless config[:db_statement] == :obfuscate

            if sql.size > config[:obfuscation_limit]
              first_match_index = sql.index(generated_postgres_regex)
              truncation_message = "SQL truncated (> #{config[:obfuscation_limit]} characters)"
              return truncation_message unless first_match_index

              truncated_sql = sql[..first_match_index - 1]
              return "#{truncated_sql}...\n#{truncation_message}"
            end

            # From:
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscator.rb
            # https://github.com/newrelic/newrelic-ruby-agent/blob/9787095d4b5b2d8fcaf2fdbd964ed07c731a8b6b/lib/new_relic/agent/database/obfuscation_helpers.rb
            obfuscated = sql.gsub(generated_postgres_regex, '?')
            obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if PG::Constants::UNMATCHED_PAIRS_REGEX.match(obfuscated)

            obfuscated
          rescue StandardError => e
            OpenTelemetry.handle_error(message: 'Failed to obfuscate SQL', exception: e)
            'OpenTelemetry error: failed to obfuscate sql'
          end

          def generated_postgres_regex
            @generated_postgres_regex ||= Regexp.union(PG::Constants::POSTGRES_COMPONENTS.map { |component| PG::Constants::COMPONENTS_REGEX_MAP[component] })
          end

          def client_attributes
            attributes = {
              'db.system' => 'postgresql',
              'db.user' => user,
              'db.name' => db
            }
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]

            attributes.merge!(transport_attrs)
            attributes.compact!
            attributes
          end

          def transport_addr
            # The hostaddr method is available when the gem is built against
            # a recent version of libpq.
            return hostaddr if defined?(hostaddr)

            # As a fallback, we can use the hostaddr of the parsed connection
            # string when there is only one. Some older versions of libpq allow
            # multiple without any way to discern which is presently connected.
            addr = conninfo_hash[:hostaddr]
            return addr unless addr&.include?(',')
          end

          def transport_attrs
            h = host
            if h&.start_with?('/')
              {
                'net.sock.family' => 'unix',
                'net.peer.name' => h
              }
            else
              {
                'net.transport' => 'ip_tcp',
                'net.peer.name' => h,
                'net.peer.ip' => transport_addr,
                'net.peer.port' => transport_port
              }
            end
          end

          def transport_port
            # The port method can fail in older versions of the gem. It is
            # accurate and safe to use when the DEF_PGPORT constant is defined.
            return port if defined?(::PG::DEF_PGPORT)

            # As a fallback, we can use the port of the parsed connection
            # string when there is exactly one.
            p = conninfo_hash[:port]
            return p.to_i unless p.nil? || p.empty? || p.include?(',')
          end
        end
      end
    end
  end
end

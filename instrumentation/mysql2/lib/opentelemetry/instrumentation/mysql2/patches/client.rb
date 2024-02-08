# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mysql2
      module Patches
        # Module to prepend to Mysql2::Client for instrumentation
        module Client
          def query(sql, options = {})
            attributes = client_attributes
            case config[:db_statement]
            when :include
              attributes[SemanticConventions::Trace::DB_STATEMENT] = sql
            when :obfuscate
              attributes[SemanticConventions::Trace::DB_STATEMENT] =
                OpenTelemetry::Helpers::SqlObfuscation.obfuscate_sql(
                  sql, obfuscation_limit: config[:obfuscation_limit], adapter: :mysql
                )
            end
            tracer.in_span(
              OpenTelemetry::Helpers::MySQL.database_span_name(
                sql,
                OpenTelemetry::Instrumentation::Mysql2.attributes[
                  SemanticConventions::Trace::DB_OPERATION
                ],
                database_name,
                config
              ),
              attributes: attributes.merge!(OpenTelemetry::Instrumentation::Mysql2.attributes),
              kind: :client
            ) do
              super(sql, options)
            end
          end

          private

          def database_name
            # https://github.com/brianmario/mysql2/blob/ca08712c6c8ea672df658bb25b931fea22555f27/lib/mysql2/client.rb#L78
            (query_options[:database] || query_options[:dbname] || query_options[:db])&.to_s
          end

          def client_attributes
            # The client specific attributes can be found via the query_options instance variable
            # exposed on the mysql2 Client
            # https://github.com/brianmario/mysql2/blob/ca08712c6c8ea672df658bb25b931fea22555f27/lib/mysql2/client.rb#L25-L26
            host = (query_options[:host] || query_options[:hostname]).to_s
            port = query_options[:port].to_s

            attributes = {
              SemanticConventions::Trace::DB_SYSTEM => 'mysql',
              SemanticConventions::Trace::NET_PEER_NAME => host,
              SemanticConventions::Trace::NET_PEER_PORT => port
            }
            attributes[SemanticConventions::Trace::DB_NAME] = database_name if database_name
            attributes[SemanticConventions::Trace::PEER_SERVICE] = config[:peer_service] if config[:peer_service]
            attributes
          end

          def tracer
            Mysql2::Instrumentation.instance.tracer
          end

          def config
            Mysql2::Instrumentation.instance.config
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Trilogy
      module Patches
        # Module to prepend to Trilogy for instrumentation
        module Client # rubocop:disable Metrics/ModuleLength
          QUERY_NAMES = [
            'set names',
            'select',
            'insert',
            'update',
            'delete',
            'begin',
            'commit',
            'rollback',
            'savepoint',
            'release savepoint',
            'explain',
            'drop database',
            'drop table',
            'create database',
            'create table'
          ].freeze

          QUERY_NAME_RE = Regexp.new("^(#{QUERY_NAMES.join('|')})", Regexp::IGNORECASE)

          COMPONENTS_REGEX_MAP = {
            single_quotes: /'(?:[^']|'')*?(?:\\'.*|'(?!'))/,
            double_quotes: /"(?:[^"]|"")*?(?:\\".*|"(?!"))/,
            numeric_literals: /-?\b(?:[0-9]+\.)?[0-9]+([eE][+-]?[0-9]+)?\b/,
            boolean_literals: /\b(?:true|false|null)\b/i,
            hexadecimal_literals: /0x[0-9a-fA-F]+/,
            comments: /(?:#|--).*?(?=\r|\n|$)/i,
            multi_line_comments: %r{\/\*(?:[^\/]|\/[^*])*?(?:\*\/|\/\*.*)}
          }.freeze

          MYSQL_COMPONENTS = %i[
            single_quotes
            double_quotes
            numeric_literals
            boolean_literals
            hexadecimal_literals
            comments
            multi_line_comments
          ].freeze

          FULL_SQL_REGEXP = Regexp.union(MYSQL_COMPONENTS.map { |component| COMPONENTS_REGEX_MAP[component] })

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
              database_span_name(sql),
              attributes: client_attributes(sql).merge!(OpenTelemetry::Instrumentation::Trilogy.attributes),
              kind: :client
            ) do
              super(sql)
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
            attributes['db.instance.id'] = @connected_host if defined?(@connected_host)

            if sql
              case config[:db_statement]
              when :obfuscate
                attributes[::OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT] = obfuscate_sql(sql)
              when :include
                attributes[::OpenTelemetry::SemanticConventions::Trace::DB_STATEMENT] = sql
              end
            end

            attributes
          end

          def obfuscate_sql(sql)
            if sql.size > config[:obfuscation_limit]
              first_match_index = sql.index(FULL_SQL_REGEXP)
              truncation_message = "SQL truncated (> #{config[:obfuscation_limit]} characters)"
              return truncation_message unless first_match_index

              truncated_sql = sql[..first_match_index - 1]
              "#{truncated_sql}...\n#{truncation_message}"
            else
              obfuscated = OpenTelemetry::Common::Utilities.utf8_encode(sql, binary: true)
              obfuscated = obfuscated.gsub(FULL_SQL_REGEXP, '?')
              obfuscated = 'Failed to obfuscate SQL query - quote characters remained after obfuscation' if detect_unmatched_pairs(obfuscated)
              obfuscated
            end
          rescue StandardError => e
            OpenTelemetry.handle_error(message: 'Failed to obfuscate SQL', exception: e)
            'OpenTelemetry error: failed to obfuscate sql'
          end

          def detect_unmatched_pairs(obfuscated)
            # We use this to check whether the query contains any quote characters
            # after obfuscation. If so, that's a good indication that the original
            # query was malformed, and so our obfuscation can't reliably find
            # literals. In such a case, we'll replace the entire query with a
            # placeholder.
            %r{'|"|\/\*|\*\/}.match(obfuscated)
          end

          def database_span_name(sql)
            case config[:span_name]
            when :statement_type
              extract_statement_type(sql)
            when :db_name
              database_name
            when :db_operation_and_name
              op = OpenTelemetry::Instrumentation::Trilogy.attributes['db.operation']
              name = database_name
              if op && name
                "#{op} #{name}"
              elsif op
                op
              elsif name
                name
              end
            end || 'mysql'
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

          def extract_statement_type(sql)
            QUERY_NAME_RE.match(sql) { |match| match[1].downcase } unless sql.nil?
          rescue StandardError => e
            OpenTelemetry.logger.error("Error extracting sql statement type: #{e.message}")
            nil
          end
        end
      end
    end
  end
end

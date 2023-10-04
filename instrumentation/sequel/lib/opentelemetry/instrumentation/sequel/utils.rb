# frozen_string_literal: true

require_relative 'ext'

module OpenTelemetry
  module Instrumentation
    module Sequel
      # General purpose functions for Sequel
      module Utils
        class << self
          # Ruby database connector library
          #
          # e.g. adapter:mysql2 (database:mysql), adapter:jdbc (database:postgres)
          def adapter_name(database)
            scheme = database.adapter_scheme.to_s

            if scheme == 'jdbc'
              # The subtype is more important in this case,
              # otherwise all database adapters will be 'jdbc'.
              database_type(database)
            else
              normalize_vendor(scheme)
            end
          end

          # Database engine
          #
          # e.g. database:mysql (adapter:mysql2), database:postgres (adapter:jdbc)
          def database_type(database)
            normalize_vendor(database.database_type.to_s)
          end

          VENDOR_DEFAULT = 'defaultdb'
          VENDOR_POSTGRES = 'postgres'
          VENDOR_SQLITE = 'sqlite'

          def normalize_vendor(vendor)
            case vendor
            when nil
              VENDOR_DEFAULT
            when 'postgresql'
              VENDOR_POSTGRES
            when 'sqlite3'
              VENDOR_SQLITE
            else
              vendor
            end
          end

          def parse_opts(sql, opts, db_opts, dataset = nil)
            # Prepared statements don't provide their sql query in the +sql+ parameter.
            if !sql.is_a?(String) && (dataset && dataset.respond_to?(:prepared_sql) &&
              (resolved_sql = dataset.prepared_sql))
              # The dataset contains the resolved SQL query and prepared statement name.
              prepared_name = dataset.prepared_statement_name.to_s
              sql = resolved_sql
            end

            {
              name: opts[:type],
              query: sql,
              prepared_name: prepared_name,
              database: db_opts[:database],
              host: db_opts[:host]
            }
          end

          def set_common_attributes(span, db)
            span.set_attribute(Ext::COMPONENT, Ext::SEQUEL)
            span.set_attribute(Ext::OPERATION, Ext::OPERATION_QUERY)

            # TODO: Extract host for Sequel with JDBC. The easiest way seem to be through
            # TODO: the database URI. Unfortunately, JDBC URIs do not work with `URI.parse`.
            # host, _port = extract_host_port_from_uri(db.uri)
            # span.set_attribute(Tracing::Metadata::Ext::TAG_DESTINATION_NAME, host)
            span.set_attribute('network.destination.name', db.opts[:host]) if db.opts[:host]
          end
        end
      end
    end
  end
end

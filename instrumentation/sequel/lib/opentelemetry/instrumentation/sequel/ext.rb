# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Sequel
      # Sequel integration constants
      # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
      module Ext
        COMPONENT = 'component'
        OPERATION = 'operation'
        SPAN_QUERY = 'sequel.query'
        SQL = 'sql'
        TAG_DB_VENDOR = 'sequel.db.vendor'
        TAG_PREPARED_NAME = 'sequel.prepared.name'
        SEQUEL = 'sequel'
        OPERATION_QUERY = 'query'
      end
    end
  end
end

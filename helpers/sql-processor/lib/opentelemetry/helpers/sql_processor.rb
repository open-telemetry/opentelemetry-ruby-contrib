# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-common'
require_relative 'sql_processor/obfuscator'
require_relative 'sql_processor/commenter'
require_relative 'sql_processor/query_summary'

module OpenTelemetry
  module Helpers
    # SQL processing utilities for OpenTelemetry instrumentation.
    #
    # This module provides a unified interface for SQL processing operations
    # commonly needed in database adapter instrumentation, including SQL obfuscation
    # and SQL comment-based trace context propagation.
    #
    # @api public
    module SqlProcessor
      module_function

      # This is a SQL obfuscation utility intended for use in database adapter instrumentation. It uses the {Obfuscator} module.
      #
      # @param sql [String] The SQL to obfuscate.
      # @param obfuscation_limit [optional Integer] the length at which the SQL string will not be obfuscated
      # @param adapter [optional Symbol] the type of database adapter calling the method. `:default`, `:mysql`, `:postgres`, `:sqlite`, `:oracle`, `:cassandra` are supported.
      # @return [String] The SQL query string where the values are replaced with "?". When the sql statement exceeds the obfuscation limit
      #  the first matched pair from the SQL statement will be returned, with an appended truncation message. If truncation is unsuccessful,
      #  a string describing the error will be returned.
      #
      # @api public
      def obfuscate_sql(sql, obfuscation_limit: 2000, adapter: :default)
        Obfuscator.obfuscate_sql(sql, obfuscation_limit: obfuscation_limit, adapter: adapter)
      end

      # Generates a high-level summary of a SQL query using the provided cache.
      #
      # @param query [String] The SQL query to summarize
      # @param cache [Cache] The cache instance to use for storing/retrieving summaries
      # @return [String] The query summary or 'UNKNOWN' if parsing fails
      #
      # @api public
      def generate_summary(query, cache:)
        QuerySummary.generate_summary(query, cache: cache)
      end
    end
  end
end

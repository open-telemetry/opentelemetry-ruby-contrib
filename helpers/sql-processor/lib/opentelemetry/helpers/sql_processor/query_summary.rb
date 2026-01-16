# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'query_summary/tokenizer'
require_relative 'query_summary/cache'
require_relative 'query_summary/parser'

module OpenTelemetry
  module Helpers
    module SqlProcessor
      # QuerySummary generates high-level summaries of SQL queries, made up of
      # key operations and table names.
      #
      # To use this in your instrumentation, create a Cache instance and pass it
      # to the generate_summary method:
      #
      # Example:
      #   cache = OpenTelemetry::Helpers::QuerySummary::Cache.new(size: 1000)
      #   summary = OpenTelemetry::Helpers::QuerySummary.generate_summary(
      #     "SELECT * FROM users WHERE id = 1",
      #     cache: cache
      #   )
      #   # => "SELECT users"
      module QuerySummary
        module_function

        # Fast path regex patterns ordered by frequency in typical SQL workloads
        # Most common patterns first to minimize regex testing overhead
        SIMPLE_PATTERNS = [
          # HIGHEST FREQUENCY: Simple SELECT * FROM table (60-70% of queries)
          [/\A\s*(SELECT)\s+\*\s+FROM\s+(\w+)\s*(?:WHERE\s+\w+\s*[=<>]\s*[^;]*)?(?:\s*;\s*)?\z/i, '\1 \2'],

          # HIGH FREQUENCY: SELECT with specific columns
          [/\A\s*(SELECT)\s+(\w+(?:\s*,\s*\w+)*)\s+FROM\s+(\w+)\s*(?:WHERE\s+[^;]*)?(?:\s*;\s*)?\z/i, '\1 \3'],

          # MEDIUM FREQUENCY: Basic DML operations
          [/\A\s*(INSERT)\s+INTO\s+(\w+)\s+VALUES\s*\(/i, '\1 \2'],
          [/\A\s*(INSERT)\s+INTO\s+(\w+)\s*\([^)]*\)\s*VALUES/i, '\1 \2'],
          [/\A\s*(UPDATE)\s+(\w+)\s+SET\s+\w+\s*=\s*[^(;]*(?:\s*;\s*)?\z/i, '\1 \2'],
          [/\A\s*(DELETE)\s+FROM\s+(\w+)\s*(?:WHERE\s+[^(;]*)?(?:\s*;\s*)?\z/i, '\1 \2'],

          # LOWER FREQUENCY: DDL operations (but high performance impact when matched)
          [/\A\s*(CREATE)\s+(TABLE)\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)\s*\(/i, '\1 \2 \3'],
          [/\A\s*(DROP)\s+(TABLE)\s+(?:IF\s+EXISTS\s+)?(\w+)\s*(?:\s*;\s*)?\z/i, '\1 \2 \3'],
          [/\A\s*(TRUNCATE)\s+(?:TABLE\s+)?(\w+)\s*(?:\s*;\s*)?\z/i, '\1 TABLE \2'],
          [/\A\s*(ALTER)\s+(TABLE)\s+(\w+)\s+/i, '\1 \2 \3'],

          # LOWER FREQUENCY: Procedure calls
          [/\A\s*(EXEC|EXECUTE|CALL)\s+(\w+)(?:\s*\(|\s|;|\z)/i, '\1 \2'],

          # LOWEST FREQUENCY: UNION queries (but biggest performance win when matched)
          [/\A\s*(SELECT)\s+[^(]*FROM\s+(\w+)\s+UNION(?:\s+ALL)?\s+SELECT\s+[^(]*FROM\s+(\w+)\s*(?:\s*;\s*)?\z/i, '\1 \2 UNION \1 \3']
        ].freeze

        # Internal implementation of SQL obfuscation.
        # Use SqlProcessor.obfuscate_sql for the public API.
        #
        # @api private
        def generate_summary(query, cache:)
          cache.fetch(query) do
            # Try fast path for simple queries first (80% of cases)
            if (summary = try_fast_path(query))
              summary
            else
              # Fall back to full tokenization and parsing
              tokens = Tokenizer.tokenize(query)
              Parser.build_summary_from_tokens(tokens)
            end
          end
        rescue StandardError
          'UNKNOWN'
        end

        # Attempt to match query against simple patterns for fast processing
        #
        # @api private
        def try_fast_path(query)
          SIMPLE_PATTERNS.each do |pattern, template|
            next unless (match = query.match(pattern))

            # Use gsub to replace capture groups in template
            result = template.gsub(/\\(\d+)/) { match[::Regexp.last_match(1).to_i] }
            # Clean up extra whitespace that might result from complex templates
            return result.gsub(/\s+/, ' ').strip
          end
          nil
        end
      end
    end
  end
end

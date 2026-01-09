# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'query_summary/tokenizer'
require_relative 'query_summary/cache'
require_relative 'query_summary/parser'

module OpenTelemetry
  module Helpers
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

      # Generates a high-level summary of a SQL query using the provided cache.
      #
      # @param query [String] The SQL query to summarize
      # @param cache [Cache] The cache instance to use for storing/retrieving summaries
      # @return [String] The query summary or 'UNKNOWN' if parsing fails
      #
      # @api public
      def generate_summary(query, cache:)
        cache.fetch(query) do
          tokens = Tokenizer.tokenize(query)
          Parser.build_summary_from_tokens(tokens)
        end
      rescue StandardError
        'UNKNOWN'
      end
    end
  end
end

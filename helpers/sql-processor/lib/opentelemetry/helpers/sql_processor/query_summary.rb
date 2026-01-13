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

        # Internal implementation of SQL obfuscation.
        # Use SqlProcessor.obfuscate_sql for the public API.
        #
        # @api private
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
end

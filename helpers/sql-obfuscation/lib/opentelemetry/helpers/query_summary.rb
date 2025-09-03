# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'query_summary/cache'
require_relative 'query_summary/tokenizer'
require_relative 'query_summary/parser'

module OpenTelemetry
  module Helpers
    # QuerySummary generates high-level summaries of SQL queries, made up of
    # key operations and table names.
    #
    # Example:
    #   QuerySummary.generate_summary("SELECT * FROM users WHERE id = 1")
    #   # => "SELECT users"
    module QuerySummary
      def self.configure_cache(size: Cache::DEFAULT_SIZE)
        Cache.configure(size: size)
      end

      def self.generate_summary(query)
        Cache.fetch(query) do
          tokens = Tokenizer.tokenize(query)
          Parser.build_summary_from_tokens(tokens)
        end
      rescue StandardError
        'UNKNOWN'
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'strscan'

module OpenTelemetry
  module Helpers
    module QuerySummary
      # Tokenizer breaks down SQL queries into structured tokens for analysis.
      #
      # Parses SQL query strings into typed tokens (keywords, identifiers, operators, literals)
      # for generating query summaries while filtering out sensitive data.
      #
      # @example
      #   tokens = Tokenizer.tokenize("SELECT * FROM users WHERE id = 1")
      #   # Returns tokens: [keyword: SELECT], [operator: *], [keyword: FROM], etc.
      class Tokenizer
        # Token holds the type (e.g., :keyword) and value (e.g., "SELECT")
        Token = Struct.new(:type, :value)

        # The order of token matching is important for correct parsing,
        # as more specific patterns should be matched before more general ones.
        TOKEN_REGEX = {
          whitespace: /\s+/,
          comment: %r{--[^\r\n]*|\/\*.*?\*\/}m,
          numeric: /[+-]?(?:0x[0-9a-fA-F]+|\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)/,
          string: /'(?:''|[^'\r\n])*'?/,
          quoted_identifier: /"(?:""|[^"\r\n])*"|`(?:``|[^`\r\n])*`|\[(?:[^\]\r\n])*\]/,
          keyword: /\b(?:SELECT|INSERT|UPDATE|DELETE|FROM|INTO|JOIN|CREATE|ALTER|DROP|TRUNCATE|WITH|UNION|TABLE|INDEX|PROCEDURE|VIEW|DATABASE)\b/i,
          identifier: /[a-zA-Z_][a-zA-Z0-9_.]*/,
          operator: /<=|>=|<>|!=|[=<>+\-*\/%,;()!?]/
        }.freeze

        EXCLUDED_TYPES = %i[whitespace comment].freeze

        def self.tokenize(query)
          scanner = StringScanner.new(query)
          tokens = []

          scan_next_token(scanner, tokens) until scanner.eos?

          tokens
        end

        def self.scan_next_token(scanner, tokens)
          matched = TOKEN_REGEX.any? do |type, regex|
            next unless (value = scanner.scan(regex))

            tokens << Token.new(type, value) unless EXCLUDED_TYPES.include?(type)
            true
          end
          scanner.getch unless matched
        end
      end
    end
  end
end

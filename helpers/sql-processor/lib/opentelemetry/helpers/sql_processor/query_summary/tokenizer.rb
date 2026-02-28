# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'strscan'
require_relative 'parser/constants'

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        # Tokenizer breaks down SQL queries into structured tokens for analysis.
        #
        # Parses SQL query strings into typed tokens (keywords, identifiers, operators, literals)
        # for generating query summaries while filtering out sensitive data.
        #
        # @example
        #   tokens = Tokenizer.tokenize("SELECT * FROM users WHERE id = 1")
        #   # Returns tokens: [:keyword, "SELECT"], [:operator, "*"], [:keyword, "FROM"], etc.
        class Tokenizer
          # Token is represented as [type, value] array for performance
          #
          # Token format: [symbol, string] where:
          #   [0] = token type (symbol)
          #   [1] = token value (string, frozen for performance)
          #
          # Token Types:
          #   :keyword           - SELECT, FROM, WHERE, CREATE, etc.
          #   :identifier        - table_name, column_name, @variable, schema.table
          #   :quoted_identifier - "table", `column`, [index], ect.
          #   :operator          - =, <, >, +, -, *, (, ), ;
          #   :numeric           - 123, -45.67, 1.2e-4
          #   :string            - 'literal text', 'O''Brien'

          KEYWORDS_ARRAY = %w[
            SELECT INSERT UPDATE DELETE
            CREATE ALTER DROP TRUNCATE
            EXEC EXECUTE CALL
            FROM INTO JOIN IN
            WITH SET WHERE BEGIN AS
            TABLE INDEX PROCEDURE VIEW DATABASE SCHEMA SEQUENCE TRIGGER FUNCTION ROLE USER
            ADD COLUMN
            RESTART START INCREMENT BY
            UNIQUE CLUSTERED DISTINCT
            UNION ALL
          ].freeze

          # Hash-based keyword lookup performance optimization
          KEYWORDS = KEYWORDS_ARRAY.each_with_object({}) { |keyword, hash| hash[keyword] = true }.freeze

          # Regex patterns ordered by frequency in typical SQL
          # Most common tokens first to reduce scanning overhead
          IDENTIFIER_REGEX = /@?[a-zA-Z_\u0080-\uffff][a-zA-Z0-9_.\u0080-\uffff]*/u
          OPERATOR_REGEX = %r{<=|>=|<>|!=|[=<>+\-*/%,;()!?]}
          NUMBER_REGEX = /[+-]?(?:\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)/
          STRING_REGEX = /'(?:''|[^'\r\n])*'/
          QUOTED_ID_REGEX = /"(?:""|[^"\r\n])*"|`(?:``|[^`\r\n])*`|\[(?:[^\]\r\n])*\]/

          # Comments and whitespace - combined for single-pass scanning
          # Ordered by frequency: whitespace most common, then line comments, then block comments
          SKIP_REGEX = %r{\s+|--[^\r\n]*|/\*.*?\*/}m

          class << self
            def tokenize(query)
              scanner = StringScanner.new(query)
              tokens = []

              until scanner.eos?
                next if scanner.scan(SKIP_REGEX)

                # Scan in order of frequency: identifiers are most common in SQL
                if (value = scanner.scan(IDENTIFIER_REGEX))
                  upcase_identifier = QuerySummary::Parser::Constants.cached_upcase(value)
                  type = KEYWORDS[upcase_identifier] ? :keyword : :identifier
                  tokens << [type, value.freeze]
                elsif (value = scanner.scan(OPERATOR_REGEX))
                  tokens << [:operator, value.freeze]
                elsif (value = scanner.scan(NUMBER_REGEX))
                  tokens << [:numeric, value.freeze]
                elsif (value = scanner.scan(STRING_REGEX))
                  tokens << [:string, value.freeze]
                elsif (value = scanner.scan(QUOTED_ID_REGEX))
                  tokens << [:quoted_identifier, value.freeze]
                else
                  # Skip unmatched characters
                  scanner.getch
                end
              end

              tokens
            end
          end
        end
      end
    end
  end
end

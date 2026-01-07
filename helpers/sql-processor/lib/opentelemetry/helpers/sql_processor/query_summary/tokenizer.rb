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
        #   :quoted_identifier - "table", `column`, [index]
        #   :operator          - =, <, >, +, -, *, (, ), ;
        #   :numeric           - 123, -45.67, 1.2e-4
        #   :string            - 'literal text', 'O''Brien'

        KEYWORDS_ARRAY = %w[
          SELECT INSERT UPDATE DELETE
          CREATE ALTER DROP TRUNCATE
          EXEC EXECUTE
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

        UPCASE_CACHE = {}
        private_constant :UPCASE_CACHE

        OPERATOR_REGEX = %r{<=|>=|<>|!=|[=<>+\-*/%,;()!?]}
        NUMBER_REGEX = /[+-]?(?:\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)/
        STRING_REGEX = /'(?:''|[^'\r\n])*'/
        QUOTED_ID_REGEX = /"(?:""|[^"\r\n])*"|`(?:``|[^`\r\n])*`|\[(?:[^\]\r\n])*\]/
        IDENTIFIER_REGEX = /@?[a-zA-Z_\u0080-\uffff][a-zA-Z0-9_.\u0080-\uffff]*/u
        COMMENT_LINE_REGEX = /--[^\r\n]*/
        COMMENT_BLOCK_REGEX = %r{/\*.*?\*/}m
        WHITESPACE_REGEX = /\s+/

        class << self
          def tokenize(query)
            scanner = StringScanner.new(query)
            tokens = []

            scan_next_token(scanner, tokens) until scanner.eos?

            tokens
          end

          def scan_next_token(scanner, tokens)
            return if skip_comments_and_whitespace(scanner)

            if (operator = scanner.scan(OPERATOR_REGEX))
              # SQL operators: comparison (<=, >=, <>, !=), equality (=), arithmetic (+, -, *, /), punctuation
              tokens << [:operator, operator.freeze]
            elsif (number = scanner.scan(NUMBER_REGEX))
              # Numbers: signed integers, decimals, scientific notation (1.23e-4)
              tokens << [:numeric, number.freeze]
            elsif (string_literal = scanner.scan(STRING_REGEX))
              # String literals with escaped quotes ('John''s Car')
              tokens << [:string, string_literal.freeze]
            elsif (quoted_name = scanner.scan(QUOTED_ID_REGEX))
              # Quoted identifiers: "double", `backtick`, [bracket] for table/column names
              tokens << [:quoted_identifier, quoted_name.freeze]
            elsif (identifier = scanner.scan(IDENTIFIER_REGEX))
              # Identifiers: table names, column names, variables (supports Unicode)
              type = classify_identifier(identifier)
              tokens << [type, identifier.freeze]
            else
              # Skip unmatched characters
              scanner.getch
            end
          end

          private

          def skip_comments_and_whitespace(scanner)
            scanner.scan(COMMENT_LINE_REGEX) || # Single-line comments (-- comment)
              scanner.scan(COMMENT_BLOCK_REGEX) ||    # Block comments (/* comment */)
              scanner.scan(WHITESPACE_REGEX)          # Whitespace (spaces, tabs, newlines)
          end

          def cached_upcase(str)
            return str if str.nil? || str.empty?

            UPCASE_CACHE[str] ||= str.upcase.freeze
          end

          def classify_identifier(identifier)
            KEYWORDS[cached_upcase(identifier)] ? :keyword : :identifier
          end
        end
      end
    end
  end
end

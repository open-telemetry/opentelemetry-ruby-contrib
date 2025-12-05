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

        KEYWORDS_ARRAY = %w[
          # Core DML operations
          SELECT INSERT UPDATE DELETE

          # Query structure and joins
          FROM INTO JOIN WHERE SET ORDER GROUP BY HAVING LIMIT

          # DDL operations
          CREATE ALTER DROP TRUNCATE

          # Advanced query features
          WITH UNION DISTINCT ALL EXISTS

          # Database objects
          TABLE INDEX PROCEDURE VIEW DATABASE SCHEMA SEQUENCE TRIGGER FUNCTION

          # Conditions and logic
          IF NOT AND OR AFTER BEFORE BEGIN END

          # Data types and constraints
          UNIQUE CLUSTERED

          # System operations
          EXEC EXECUTE ROLE USER RESTART TRANSFER

          # Column operations
          ADD MODIFY RENAME COLUMN TO INCLUDE REBUILD MEMBER PASSWORD
        ].freeze

        # Hash-based keyword lookup performance optimization
        KEYWORDS = KEYWORDS_ARRAY.each_with_object({}) { |keyword, hash| hash[keyword] = true }.freeze

        class << self
          def tokenize(query)
            scanner = StringScanner.new(query)
            tokens = []

            scan_next_token(scanner, tokens) until scanner.eos?

            tokens
          end

          def scan_next_token(scanner, tokens)
            return if skip_comments_and_whitespace(scanner)

            case
            when (operator = scanner.scan(%r{<=|>=|<>|!=|[=<>+\-*/%,;()!?]}))
              # SQL operators: comparison (<=, >=, <>, !=), equality (=), arithmetic (+, -, *, /), punctuation
              tokens << Token.new(:operator, operator)
            when (number = scanner.scan(/[+-]?(?:\d+\.?\d*(?:[eE][+-]?\d+)?|0x[0-9a-fA-F]+|\.\d+(?:[eE][+-]?\d+)?)/))
              # Numbers: signed integers, decimals, scientific notation (1.23e-4), hex (0xFF)
              tokens << Token.new(:numeric, number)
            when (string_literal = scanner.scan(/'(?:''|[^'\r\n])*'/))
              # String literals with escaped quotes ('John''s Car')
              tokens << Token.new(:string, string_literal)
            when (quoted_name = scanner.scan(/"(?:""|[^"\r\n])*"|`(?:``|[^`\r\n])*`|\[(?:[^\]\r\n])*\]/))
              # Quoted identifiers: "double", `backtick`, [bracket] for table/column names
              tokens << Token.new(:quoted_identifier, quoted_name)
            when (identifier = scanner.scan(/@?[a-zA-Z_\u0080-\uffff][a-zA-Z0-9_.\u0080-\uffff]*/u))
              # Identifiers: table names, column names, variables (supports Unicode)
              type = classify_identifier(identifier)
              tokens << Token.new(type, identifier)
            else
              # Skip unmatched characters
              scanner.getch
            end
          end

          private

          def skip_comments_and_whitespace(scanner)
            scanner.scan(/--[^\r\n]*/) ||     # Single-line comments (-- comment)
            scanner.scan(%r{/\*.*?\*/}m) ||   # Block comments (/* comment */)
            scanner.scan(/\s+/)               # Whitespace (spaces, tabs, newlines)
          end

          def classify_identifier(identifier)
            KEYWORDS[identifier.upcase] ? :keyword : :identifier
          end
        end
      end
    end
  end
end

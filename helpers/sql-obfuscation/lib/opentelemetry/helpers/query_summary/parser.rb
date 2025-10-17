# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module QuerySummary
      # Parser builds high-level SQL query summaries from tokenized input.
      #
      # Processes tokens to extract key operations and table names, creating
      # summaries like "SELECT users" or "INSERT INTO orders".
      #
      # @example
      #   tokens = [Token.new(:keyword, "SELECT"), Token.new(:identifier, "users")]
      #   Parser.build_summary_from_tokens(tokens) # => "SELECT users"
      class Parser
        # Two states: normal parsing vs. waiting for table names
        PARSING_STATE = :parsing
        EXPECT_COLLECTION_STATE = :expect_collection

        MAIN_OPERATIONS = %w[SELECT INSERT DELETE].freeze # Operations that start queries and need table names
        COLLECTION_OPERATIONS = %w[WITH UPDATE].freeze # Operations that work with existing data and expect table names to follow
        TRIGGER_COLLECTION = %w[FROM INTO JOIN IN].freeze # Keywords that signal a table name is coming next
        TABLE_OPERATIONS = %w[CREATE ALTER DROP TRUNCATE].freeze # Database structure operations that create, modify, or remove objects
        TABLE_OBJECTS = %w[TABLE INDEX PROCEDURE VIEW DATABASE].freeze # Types of database objects that can be created, modified, or removed

        class << self
          def build_summary_from_tokens(tokens)
            summary_parts = []
            state = PARSING_STATE
            skip_until = 0 # Skip tokens we've already processed when looking ahead

            tokens.each_with_index do |token, index|
              next if index < skip_until

              result = process_token(token, tokens, index, state)

              summary_parts.concat(result[:parts])
              state = result[:new_state]
              skip_until = result[:next_index]
            end

            summary_parts.join(' ')
          end

          def process_token(token, tokens, index, state)
            operation_result = process_main_operation(token, tokens, index, state)
            return operation_result if operation_result[:processed]

            collection_result = process_collection_token(token, tokens, index, state)
            return collection_result if collection_result[:processed]

            { processed: false, parts: [], new_state: state, next_index: index + 1 }
          end

          def process_main_operation(token, tokens, index, current_state)
            upcased_value = token.value.upcase

            case upcased_value
            when *MAIN_OPERATIONS
              add_to_summary(token.value, PARSING_STATE, index + 1)
            when *COLLECTION_OPERATIONS
              add_to_summary(token.value, EXPECT_COLLECTION_STATE, index + 1)
            when *TRIGGER_COLLECTION
              expect_table_names_next(index + 1)
            when *TABLE_OPERATIONS
              handle_table_operation(token, tokens, index)
            when 'UNION'
              handle_union(token, tokens, index)
            else
              not_processed(current_state, index + 1)
            end
          end

          def process_collection_token(token, tokens, index, state)
            return not_processed(state, index + 1) unless state == EXPECT_COLLECTION_STATE

            upcased_value = token.value.upcase

            if identifier_like?(token) || (token.type == :keyword && can_be_table_name?(upcased_value))
              process_table_name_and_alias(token, tokens, index)
            elsif token.value == '(' || token.type == :operator
              handle_collection_operator(token, state, index)
            else
              return_to_normal_parsing(token, index)
            end
          end

          def process_table_name_and_alias(token, tokens, index)
            # Look ahead to skip table aliases (e.g., "users u" or "users AS u")
            skip_count = calculate_alias_skip(tokens, index)
            # Check if there's a comma - if so, expect more table names in the list
            new_state = tokens[index + 1 + skip_count]&.value == ',' ? EXPECT_COLLECTION_STATE : PARSING_STATE
            skip_count += 1 if tokens[index + 1 + skip_count]&.value == ','

            { processed: true, parts: [token.value], new_state: new_state, next_index: index + 1 + skip_count }
          end

          def handle_collection_operator(token, state, index)
            { processed: true, parts: [], new_state: state, next_index: index + 1 }
          end

          def return_to_normal_parsing(token, index)
            { processed: true, parts: [], new_state: PARSING_STATE, next_index: index + 1 }
          end

          def identifier_like?(token)
            %i[identifier quoted_identifier string].include?(token.type)
          end

          def can_be_table_name?(upcased_value)
            # Object types that can appear after DDL operations
            TABLE_OBJECTS.include?(upcased_value)
          end

          def calculate_alias_skip(tokens, index)
            # Handle both "table AS alias" and "table alias" patterns
            next_token = tokens[index + 1]
            if next_token && next_token.value&.upcase == 'AS'
              2
            elsif next_token && next_token.type == :identifier
              1
            else
              0
            end
          end

          def add_to_summary(part, new_state, next_index)
            { processed: true, parts: [part], new_state: new_state, next_index: next_index }
          end

          def expect_table_names_next(next_index)
            { processed: true, parts: [], new_state: EXPECT_COLLECTION_STATE, next_index: next_index }
          end

          def not_processed(current_state, next_index)
            { processed: false, parts: [], new_state: current_state, next_index: next_index }
          end

          def handle_union(token, tokens, index)
            next_token = tokens[index + 1]
            if next_token && next_token.value&.upcase == 'ALL'
              { processed: true, parts: ["#{token.value} #{next_token.value}"], new_state: PARSING_STATE, next_index: index + 2 }
            else
              add_to_summary(token.value, PARSING_STATE, index + 1)
            end
          end

          def handle_table_operation(token, tokens, index)
            # Combine DDL operations with object types: "CREATE TABLE", "DROP INDEX", etc.
            next_token_obj = tokens[index + 1]
            next_token = next_token_obj&.value&.upcase

            case next_token
            when 'TABLE', 'INDEX', 'PROCEDURE', 'VIEW', 'DATABASE'
              { processed: true, parts: ["#{token.value} #{next_token}"], new_state: EXPECT_COLLECTION_STATE, next_index: index + 2 }
            else
              add_to_summary(token.value, PARSING_STATE, index + 1)
            end
          end
        end
      end
    end
  end
end

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
        def self.build_summary_from_tokens(tokens)
          summary_parts = []
          state = :default # Either :default or :expect_collection
          skip_until = 0 # Next token index to process; allows skipping tokens already consumed by previous operations

          tokens.each_with_index do |token, index|
            next if index < skip_until # Skip already processed tokens

            result = process_token(token, tokens, index, state)

            summary_parts.concat(result[:parts])
            state = result[:new_state]
            skip_until = result[:next_index]
          end

          summary_parts.join(' ')
        end

        def self.process_token(token, tokens, index, state)
          operation_result = process_main_operation(token, tokens, index, state)
          return operation_result if operation_result[:processed]

          collection_result = process_collection_token(token, tokens, index, state)
          return collection_result if collection_result[:processed]

          { processed: false, parts: [], new_state: state, next_index: index + 1 }
        end

        def self.process_main_operation(token, tokens, index, current_state)
          case token.value.upcase
          when 'SELECT', 'INSERT', 'DELETE'
            add_to_summary(token.value, :default, index + 1)
          when 'WITH', 'UPDATE'
            add_to_summary(token.value, :expect_collection, index + 1)
          when 'FROM', 'INTO', 'JOIN', 'IN'
            trigger_collection_mode(index + 1)
          when 'CREATE', 'ALTER', 'DROP', 'TRUNCATE'
            handle_table_operation(token, tokens, index)
          when 'UNION'
            handle_union(token, tokens, index)
          else
            not_processed(current_state, index + 1)
          end
        end

        def self.process_collection_token(token, tokens, index, state)
          return { processed: false, parts: [], new_state: state, next_index: index + 1 } unless state == :expect_collection

          upcased_value = token.value.upcase

          if identifier_like?(token) || (token.type == :keyword && can_be_table_name?(upcased_value))
            skip_count = calculate_alias_skip(tokens, index)
            new_state = tokens[index + 1 + skip_count]&.value == ',' ? :expect_collection : :default
            skip_count += 1 if tokens[index + 1 + skip_count]&.value == ','

            { processed: true, parts: [token.value], new_state: new_state, next_index: index + 1 + skip_count }
          elsif token.value == '(' || token.type == :operator
            { processed: true, parts: [], new_state: state, next_index: index + 1 }
          else
            { processed: true, parts: [], new_state: :default, next_index: index + 1 }
          end
        end

        def self.identifier_like?(token)
          %i[identifier quoted_identifier string].include?(token.type)
        end

        def self.can_be_table_name?(upcased_value)
          # Keywords that can also be used as table/object names in certain contexts
          %w[TABLE INDEX PROCEDURE VIEW DATABASE].include?(upcased_value)
        end

        def self.calculate_alias_skip(tokens, index)
          if tokens[index + 1]&.value&.upcase == 'AS'
            2  # Skip 'AS' and the alias
          elsif tokens[index + 1]&.type == :identifier
            1  # Skip the alias
          else
            0
          end
        end

        def self.add_to_summary(part, new_state, next_index)
          { processed: true, parts: [part], new_state: new_state, next_index: next_index }
        end

        def self.trigger_collection_mode(next_index)
          { processed: true, parts: [], new_state: :expect_collection, next_index: next_index }
        end

        def self.not_processed(current_state, next_index)
          { processed: false, parts: [], new_state: current_state, next_index: next_index }
        end

        def self.handle_union(token, tokens, index)
          if tokens[index + 1]&.value&.upcase == 'ALL'
            { processed: true, parts: ["#{token.value} #{tokens[index + 1].value}"], new_state: :default, next_index: index + 2 }
          else
            add_to_summary(token.value, :default, index + 1)
          end
        end

        def self.handle_table_operation(token, tokens, index)
          next_token = tokens[index + 1]&.value&.upcase

          case next_token
          when 'TABLE', 'INDEX', 'PROCEDURE', 'VIEW', 'DATABASE'
            { processed: true, parts: ["#{token.value} #{next_token}"], new_state: :expect_collection, next_index: index + 2 }
          else
            add_to_summary(token.value, :default, index + 1)
          end
        end
      end
    end
  end
end

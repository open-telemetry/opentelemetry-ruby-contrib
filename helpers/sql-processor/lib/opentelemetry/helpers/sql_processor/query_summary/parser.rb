# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'parser/constants'
require_relative 'parser/token_processor'
require_relative 'parser/ddl_handler'
require_relative 'parser/table_processor'
require_relative 'parser/operation_handler'
require_relative 'parser/summary_consolidator'

module OpenTelemetry
  module Helpers
    module SqlProcessor
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
          extend Constants
          extend TokenProcessor
          extend DdlHandler
          extend TableProcessor
          extend OperationHandler
          extend SummaryConsolidator

          class << self
            def build_summary_from_tokens(tokens)
              # Pre-allocate array to reduce reallocations during concat
              # Summary parts are typically much smaller than token count
              summary_parts = Array.new([tokens.length / 4, 8].max)
              summary_parts.clear # Start with empty array but keep allocated capacity
              state = Constants::PARSING_STATE
              skip_until = 0 # Skip tokens we've already processed when looking ahead
              in_clause_context = false # Track if we're in an IN clause context

              # Process tokens to build summary parts
              tokens.each_with_index do |token, index|
                next if index < skip_until

                # Cache token value to reduce array access
                token_value = token[Constants::VALUE_INDEX]

                # Update IN clause context
                if Constants.cached_upcase(token_value) == 'IN'
                  in_clause_context = true
                elsif token_value == '(' && in_clause_context
                # Continue in IN clause context until we find closing parenthesis
                elsif token_value == ')' && in_clause_context
                  in_clause_context = false
                end

                result = TokenProcessor.process_token(token, tokens, index,
                                                      state: state,
                                                      in_clause_context: in_clause_context)

                summary_parts.concat(result[:parts])
                state = result[:new_state]
                skip_until = result[:next_index]
              end

              # Post-process to consolidate UNION queries
              summary = SummaryConsolidator.consolidate_union_queries(summary_parts).join(' ')

              truncate_summary(summary)
            end

            private

            def truncate_summary(summary)
              return summary if summary.length <= Constants::MAX_SUMMARY_LENGTH

              # Find the last complete word that fits within the limit
              truncated = summary[0...Constants::MAX_SUMMARY_LENGTH]
              last_space_index = truncated.rindex(' ')

              # If no space found, or it would make the result too short (less than 80% of limit),
              # truncate at the character limit to ensure we get something meaningful
              if last_space_index.nil? || last_space_index < Constants::MAX_SUMMARY_LENGTH * 0.8
                truncated
              else
                # Truncate at the last complete word boundary
                truncated[0...last_space_index]
              end
            end
          end
        end
      end
    end
  end
end

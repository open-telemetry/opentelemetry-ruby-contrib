# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        class Parser
          # Token processing logic for SQL query parsing
          module TokenProcessor
            def process_token(token, tokens, index, **options)
              state = options[:state]
              return { processed: true, parts: [], new_state: state, next_index: index + 1 } if state == Constants::DDL_BODY_STATE

              # Try main operations
              res = process_main_operation(token, tokens, index, options)
              return res if res[:processed]

              # Try collection logic
              res = process_collection_token(token, tokens, index, options)
              return res if res[:processed]

              { processed: false, parts: [], new_state: state, next_index: index + 1 }
            end

            def process_main_operation(token, tokens, index, options)
              state = options[:state]
              return not_processed(state, index + 1) if options[:in_clause_context]

              val = token[Constants::VALUE_INDEX]
              upcased = Constants.cached_upcase(val)

              case upcased
              when 'AS'
                OperationHandler.handle_as_keyword(token, tokens, index, state)
              when *Constants::MAIN_OPERATIONS
                add_to_summary(val, Constants::PARSING_STATE, index + 1)
              when *Constants::COLLECTION_OPERATIONS
                # Optimized lookback for OPENJSON WITH without array slicing
                if upcased == 'WITH' && index.positive?
                  found_openjson = false
                  start_idx = [0, index - 5].max
                  (index - 1).downto(start_idx) do |i|
                    if Constants.cached_upcase(tokens[i][Constants::VALUE_INDEX]) == 'OPENJSON'
                      found_openjson = true
                      break
                    end
                  end
                  return not_processed(state, index + 1) if found_openjson
                end

                add_to_summary(val, Constants::EXPECT_COLLECTION_STATE, index + 1)
              when *Constants::UPDATE_OPERATIONS
                OperationHandler.handle_update_operation(token, tokens, index)
              when *Constants::TRIGGER_COLLECTION
                expect_table_names_next(index + 1)
              when *Constants::TABLE_OPERATIONS
                OperationHandler.handle_table_operation(token, tokens, index)
              when *Constants::EXEC_OPERATIONS
                OperationHandler.handle_exec_operation(token, tokens, index)
              when 'UNION'
                OperationHandler.handle_union(token, tokens, index)
              else
                not_processed(state, index + 1)
              end
            end

            def process_collection_token(token, tokens, index, options)
              state = options[:state]
              return not_processed(state, index + 1) unless state == Constants::EXPECT_COLLECTION_STATE

              upcased = Constants.cached_upcase(token[Constants::VALUE_INDEX])

              if upcased == 'AS'
                { processed: true, parts: [], new_state: Constants::DDL_BODY_STATE, next_index: index + 1 }
              # RE-ADDED: support for :string type tokens here
              elsif identifier_like?(token) ||
                    (token[Constants::TYPE_INDEX] == :string && !options[:in_clause_context]) ||
                    (token[Constants::TYPE_INDEX] == :keyword && can_be_table_name?(upcased))

                DdlHandler.process_table_name_and_alias(token, tokens, index)
              elsif token[Constants::VALUE_INDEX] == '(' || token[Constants::TYPE_INDEX] == :operator
                handle_collection_operator(token, state, index)
              else
                return_to_normal_parsing(token, index)
              end
            end

            def identifier_like?(token)
              type = token[Constants::TYPE_INDEX]
              %i[identifier quoted_identifier].include?(type)
            end

            def can_be_table_name?(upcased_value)
              Constants::TABLE_OBJECTS.include?(upcased_value)
            end

            def handle_collection_operator(_token, state, index)
              { processed: true, parts: [], new_state: state, next_index: index + 1 }
            end

            def return_to_normal_parsing(_token, index)
              { processed: true, parts: [], new_state: Constants::PARSING_STATE, next_index: index + 1 }
            end

            def add_to_summary(part, new_state, next_index)
              { processed: true, parts: [part], new_state: new_state, next_index: next_index }
            end

            def expect_table_names_next(next_index)
              { processed: true, parts: [], new_state: Constants::EXPECT_COLLECTION_STATE, next_index: next_index }
            end

            def not_processed(current_state, next_index)
              { processed: false, parts: [], new_state: current_state, next_index: next_index }
            end

            module_function :process_token, :process_main_operation, :process_collection_token,
                            :identifier_like?, :can_be_table_name?, :handle_collection_operator,
                            :return_to_normal_parsing, :add_to_summary, :expect_table_names_next,
                            :not_processed
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        class Parser
          # Handlers for specific SQL operations
          # rubocop:disable Metrics/ModuleLength
          module OperationHandler
            def handle_union(token, tokens, index)
              next_token = tokens[index + 1]
              if next_token && Constants.cached_upcase(next_token[Constants::VALUE_INDEX]) == 'ALL'
                { processed: true, parts: ["#{token[Constants::VALUE_INDEX]} #{next_token[Constants::VALUE_INDEX]}"], new_state: Constants::PARSING_STATE, next_index: index + 2 }
              else
                TokenProcessor.add_to_summary(token[Constants::VALUE_INDEX], Constants::PARSING_STATE, index + 1)
              end
            end

            def handle_table_operation(token, tokens, index)
              result = handle_ddl_with_if_exists(token, tokens, index)
              return result if result[:processed]

              object_type_token = nil
              search_index = index + 1
              while search_index < tokens.length
                candidate = tokens[search_index]
                break unless candidate

                upcased = Constants.cached_upcase(candidate[Constants::VALUE_INDEX])
                if Constants::TABLE_OBJECTS.include?(upcased)
                  object_type_token = candidate
                  break
                elsif Constants::UNIQUE_KEYWORDS.include?(upcased)
                  search_index += 1
                else
                  break
                end
              end
              if object_type_token
                { processed: true, parts: ["#{token[Constants::VALUE_INDEX]} #{Constants.cached_upcase(object_type_token[Constants::VALUE_INDEX])}"], new_state: Constants::EXPECT_COLLECTION_STATE, next_index: search_index + 1 }
              else
                TokenProcessor.add_to_summary(token[Constants::VALUE_INDEX], Constants::PARSING_STATE, index + 1)
              end
            end

            def handle_ddl_with_if_exists(token, tokens, index)
              operation = token[Constants::VALUE_INDEX]
              next_token = tokens[index + 1]
              return { processed: false, parts: [], new_state: Constants::PARSING_STATE, next_index: index + 1 } unless next_token

              upcased_next = Constants.cached_upcase(next_token[Constants::VALUE_INDEX])
              # [CREATE|DROP] [OBJECT] IF [NOT] EXISTS - Look for "IF" at index + 2
              if Constants::TABLE_OBJECTS.include?(upcased_next) && (if_tok = tokens[index + 2]) && Constants.cached_upcase(if_tok[Constants::VALUE_INDEX]) == 'IF'
                # CREATE TABLE IF NOT EXISTS
                if Constants.cached_upcase(operation) == 'CREATE' &&
                   (not_tok = tokens[index + 3]) && Constants.cached_upcase(not_tok[Constants::VALUE_INDEX]) == 'NOT' &&
                   (ex_tok = tokens[index + 4]) && Constants.cached_upcase(ex_tok[Constants::VALUE_INDEX]) == 'EXISTS'
                  obj_name = tokens[index + 5]
                  return ddl_summary(operation, upcased_next, obj_name, index + 6) if obj_name
                # DROP TABLE IF EXISTS
                elsif (ex_tok = tokens[index + 3]) && Constants.cached_upcase(ex_tok[Constants::VALUE_INDEX]) == 'EXISTS'
                  obj_name = tokens[index + 4]
                  return ddl_summary(operation, upcased_next, obj_name, index + 5) if obj_name
                end
              end
              { processed: false, parts: [], new_state: Constants::PARSING_STATE, next_index: index + 1 }
            end

            def handle_exec_operation(token, tokens, index)
              next_token = tokens[index + 1]
              if next_token && %i[identifier quoted_identifier].include?(next_token[Constants::TYPE_INDEX])
                { processed: true, parts: ["#{token[Constants::VALUE_INDEX]} #{next_token[Constants::VALUE_INDEX]}"], new_state: Constants::PARSING_STATE, next_index: index + 2 }
              else
                TokenProcessor.add_to_summary(token[Constants::VALUE_INDEX], Constants::PARSING_STATE, index + 1)
              end
            end

            def handle_update_operation(token, tokens, index)
              table_token = tokens[index + 1]
              set_token = tokens[index + 2]
              if table_token && set_token && Constants.cached_upcase(set_token[Constants::VALUE_INDEX]) == 'SET'
                has_parenthesized_constant = false
                (index + 3).upto(tokens.length - 1) do |i|
                  if tokens[i][Constants::VALUE_INDEX] == '('
                    has_parenthesized_constant = true
                    break
                  end
                end
                if has_parenthesized_constant && table_token[Constants::VALUE_INDEX].length == 1
                  TokenProcessor.add_to_summary(token[Constants::VALUE_INDEX], Constants::PARSING_STATE, index + 1)
                else
                  TokenProcessor.add_to_summary(token[Constants::VALUE_INDEX], Constants::EXPECT_COLLECTION_STATE, index + 1)
                end
              else
                TokenProcessor.add_to_summary(token[Constants::VALUE_INDEX], Constants::EXPECT_COLLECTION_STATE, index + 1)
              end
            end

            def handle_as_keyword(token, tokens, index, current_state)
              # Search backwards without slicing the array
              has_ddl_operation = false
              (index - 1).downto(0) do |i|
                t_val = Constants.cached_upcase(tokens[i][Constants::VALUE_INDEX])
                if Constants::DDL_OPERATIONS.include?(t_val)
                  has_ddl_operation = true
                  break
                end
                break if Constants::MAIN_OPERATIONS.include?(t_val) # Stop at statement start
              end
              if has_ddl_operation
                { processed: true, parts: [], new_state: Constants::DDL_BODY_STATE, next_index: index + 1 }
              else
                TokenProcessor.not_processed(current_state, index + 1)
              end
            end

            def identifier_like?(token)
              %i[identifier quoted_identifier].include?(token[Constants::TYPE_INDEX])
            end

            # Internal helper to keep code DRY
            def ddl_summary(operation, type, name_tok, next_idx)
              { processed: true, parts: ["#{operation} #{type} #{name_tok[Constants::VALUE_INDEX]}"], new_state: Constants::PARSING_STATE, next_index: next_idx }
            end

            module_function :handle_union, :handle_table_operation, :handle_ddl_with_if_exists, :handle_exec_operation, :handle_update_operation, :handle_as_keyword, :identifier_like?, :ddl_summary
          end
          # rubocop:enable Metrics/ModuleLength
        end
      end
    end
  end
end

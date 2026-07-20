# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        class Parser
          # DDL-specific handling for procedures, triggers, and AS patterns
          module DdlHandler
            # Start keywords that indicate a body should be skipped
            DDL_BODY_START_KEYWORDS = %w[SELECT INSERT UPDATE DELETE BEGIN].each_with_object({}) { |kw, h| h[kw] = true }.freeze

            def process_table_name_and_alias(token, tokens, index)
              # Priority 1: Check for stored procedures and triggers
              result = handle_procedure_as_begin_pattern(token, tokens, index) ||
                       handle_ddl_as_pattern(token, tokens, index) ||
                       handle_trigger_as_begin_pattern(token, tokens, index)

              return result if result

              # Priority 2: Standard table/alias handling
              TableProcessor.handle_regular_table_name(token, tokens, index)
            end

            def handle_procedure_as_begin_pattern(token, tokens, index)
              as_token = tokens[index + 1]
              begin_token = tokens[index + 2]

              return unless as_token && Constants.cached_upcase(as_token[Constants::VALUE_INDEX]) == 'AS'
              return unless begin_token && Constants.cached_upcase(begin_token[Constants::VALUE_INDEX]) == 'BEGIN'

              # PROCEDURE name AS BEGIN -> we keep the name and stay in PARSING_STATE to see the body
              {
                processed: true,
                parts: [token[Constants::VALUE_INDEX]],
                new_state: Constants::PARSING_STATE,
                next_index: index + 3
              }
            end

            def handle_ddl_as_pattern(token, tokens, index)
              next_token = tokens[index + 1]
              return nil unless next_token && Constants.cached_upcase(next_token[Constants::VALUE_INDEX]) == 'AS'

              after_as_token = tokens[index + 2]
              return unless after_as_token

              upcased_after = Constants.cached_upcase(after_as_token[Constants::VALUE_INDEX])
              return unless DDL_BODY_START_KEYWORDS[upcased_after]

              # For non-procedure DDL, skip the body entirely
              {
                processed: true,
                parts: [token[Constants::VALUE_INDEX]],
                new_state: Constants::DDL_BODY_STATE,
                next_index: index + 2
              }
            end

            def handle_trigger_as_begin_pattern(token, tokens, index)
              look_ahead_index = find_as_begin_pattern(tokens, index + 1, index + 11)
              return nil unless look_ahead_index

              {
                processed: true,
                parts: [token[Constants::VALUE_INDEX]],
                new_state: Constants::DDL_BODY_STATE,
                next_index: look_ahead_index + 1
              }
            end

            def find_as_begin_pattern(tokens, start_idx, end_idx)
              look_ahead_index = start_idx
              limit = [tokens.length, end_idx].min

              while look_ahead_index < limit
                current_token = tokens[look_ahead_index]
                look_ahead_index += 1

                if current_token && Constants.cached_upcase(current_token[Constants::VALUE_INDEX]) == 'AS'
                  next_after_as = tokens[look_ahead_index]
                  return look_ahead_index if next_after_as && Constants.cached_upcase(next_after_as[Constants::VALUE_INDEX]) == 'BEGIN'
                end
              end

              nil
            end

            module_function :process_table_name_and_alias, :handle_procedure_as_begin_pattern,
                            :handle_ddl_as_pattern, :handle_trigger_as_begin_pattern, :find_as_begin_pattern
          end
        end
      end
    end
  end
end

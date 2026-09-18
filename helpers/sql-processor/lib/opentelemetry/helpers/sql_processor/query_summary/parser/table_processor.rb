# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        class Parser
          # Table name processing, alias handling, and state management
          module TableProcessor
            # Keywords that signify the end of a table list and transition back to normal parsing
            STOP_KEYWORDS = %w[WITH SET WHERE BEGIN DROP ADD COLUMN INCREMENT BY].each_with_object({}) { |kw, h| h[kw] = true }.freeze

            def handle_regular_table_name(token, tokens, index)
              skip_count = calculate_alias_skip(tokens, index)
              state_result = determine_next_state_after_table(tokens, index, skip_count)

              cleaned_table_name = clean_table_name(token[Constants::VALUE_INDEX])

              {
                processed: true,
                parts: [cleaned_table_name],
                new_state: state_result[:new_state],
                next_index: index + 1 + state_result[:skip_count],
                terminate_after_ddl: state_result[:should_terminate]
              }
            end

            def determine_next_state_after_table(tokens, index, initial_skip_count)
              skip_count = initial_skip_count
              next_token = tokens[index + 1 + skip_count]
              return { new_state: Constants::PARSING_STATE, skip_count: skip_count, should_terminate: false } unless next_token

              val = next_token[Constants::VALUE_INDEX]
              upcased_val = Constants.cached_upcase(val)

              if %w[START RESTART].include?(upcased_val)
                skip_count += handle_start_restart_pattern(tokens, index, skip_count)
                { new_state: Constants::PARSING_STATE, skip_count: skip_count, should_terminate: false }
              elsif STOP_KEYWORDS[upcased_val]
                { new_state: Constants::PARSING_STATE, skip_count: skip_count + 1, should_terminate: false }
              elsif val == ','
                # Comma found: stay in collection state to get the next table name
                { new_state: Constants::EXPECT_COLLECTION_STATE, skip_count: skip_count + 1, should_terminate: false }
              else
                { new_state: Constants::PARSING_STATE, skip_count: skip_count, should_terminate: false }
              end
            end

            def handle_start_restart_pattern(tokens, index, current_skip)
              following_token = tokens[index + 2 + current_skip]
              if following_token && Constants.cached_upcase(following_token[Constants::VALUE_INDEX]) == 'WITH'
                2
              else
                1
              end
            end

            def calculate_alias_skip(tokens, index)
              next_token = tokens[index + 1]
              return 0 unless next_token

              upcased_next = Constants.cached_upcase(next_token[Constants::VALUE_INDEX])

              if upcased_next == 'AS'
                2
              elsif next_token[Constants::TYPE_INDEX] == :identifier
                1
              else
                0
              end
            end

            def clean_table_name(table_name)
              return table_name if table_name.length < 2

              first = table_name[0]
              last = table_name[-1]

              if (first == '[' && last == ']') || (first == '`' && last == '`')
                table_name[1..-2]
              else
                table_name
              end
            end

            module_function :handle_regular_table_name, :determine_next_state_after_table,
                            :handle_start_restart_pattern, :calculate_alias_skip, :clean_table_name
          end
        end
      end
    end
  end
end

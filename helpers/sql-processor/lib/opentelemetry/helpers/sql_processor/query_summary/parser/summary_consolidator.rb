# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        class Parser
          # Summary consolidation logic for handling UNION queries
          module SummaryConsolidator
            def consolidate_union_queries(summary_parts)
              result = []
              i = 0

              while i < summary_parts.length
                current = summary_parts[i]

                # If we hit a SELECT, check if it's the start of a UNION chain
                if current == 'SELECT'
                  i += 1
                  table_names, i = collect_table_names_from_position(summary_parts, i)

                  # Look ahead for UNION/UNION ALL chains
                  i = process_union_chain(summary_parts, i, table_names)

                  result << 'SELECT'
                  # uniq prevents "SELECT users users" in cases of self-union
                  result.concat(table_names.uniq)
                else
                  result << current
                  i += 1
                end
              end

              result
            end

            # Helper method to collect table names from a starting position
            # Returns [table_names_array, new_index]
            def collect_table_names_from_position(summary_parts, start_index)
              table_names = []
              i = start_index

              while i < summary_parts.length
                item = summary_parts[i]

                # Stop if we hit a keyword that signals a new operation
                # We reuse the Constant sets here for consistency
                break if Constants::MAIN_OPERATIONS.include?(item) ||
                         Constants::UNION_SELECT_KEYWORDS.include?(item) ||
                         Constants::TABLE_OPERATIONS.include?(item)

                table_names << item
                i += 1
              end

              [table_names, i]
            end

            # Helper method to process UNION chain and collect all table names
            # Returns new index after processing the chain
            def process_union_chain(summary_parts, start_index, table_names)
              i = start_index

              while i < summary_parts.length && summary_parts[i] == 'UNION'
                i += 1 # Skip UNION
                i += 1 if i < summary_parts.length && summary_parts[i] == 'ALL' # Skip ALL if present

                # Continue if the next word is SELECT
                break unless i < summary_parts.length && summary_parts[i] == 'SELECT'

                i += 1
                additional_names, i = collect_table_names_from_position(summary_parts, i)
                table_names.concat(additional_names)

                # Hit UNION but no SELECT follows; break the chain

              end

              i
            end

            module_function :consolidate_union_queries, :collect_table_names_from_position,
                            :process_union_chain
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Helpers
    module SqlProcessor
      module QuerySummary
        class Parser
          # Constants and configuration for SQL query parsing
          module Constants
            # Three states: normal parsing vs. waiting for table names vs. DDL body (skip everything)
            #
            # State Machine:
            #   PARSING_STATE          - Default state: looking for SQL operations (SELECT, CREATE, etc.)
            #   EXPECT_COLLECTION_STATE - Collecting table names after FROM, INTO, JOIN keywords
            #   DDL_BODY_STATE         - Inside procedure/trigger body: skip all tokens until end
            #
            # State Transitions:
            #   PARSING_STATE → EXPECT_COLLECTION_STATE:  when hitting FROM, INTO, JOIN, or main operations
            #   EXPECT_COLLECTION_STATE → PARSING_STATE:  when hitting WHERE, SET, or end of table list
            #   EXPECT_COLLECTION_STATE → DDL_BODY_STATE: when hitting AS BEGIN (procedure/trigger body)
            #   DDL_BODY_STATE → stays until end of input (skips everything inside DDL bodies)
            PARSING_STATE = :parsing
            EXPECT_COLLECTION_STATE = :expect_collection
            DDL_BODY_STATE = :ddl_body

            # Array indices for token access (matches tokenizer)
            TYPE_INDEX = 0
            VALUE_INDEX = 1

            # Frozen sets for O(1) lookups
            # These are used with the splat operator (*) in case statements
            MAIN_OPERATIONS = %w[SELECT INSERT DELETE].to_set.freeze
            COLLECTION_OPERATIONS = %w[WITH].to_set.freeze
            UPDATE_OPERATIONS = %w[UPDATE].to_set.freeze
            TRIGGER_COLLECTION = %w[FROM INTO JOIN IN].to_set.freeze
            TABLE_OPERATIONS = %w[CREATE ALTER DROP TRUNCATE].to_set.freeze
            TABLE_OBJECTS = %w[TABLE INDEX PROCEDURE VIEW DATABASE ROLE USER SCHEMA SEQUENCE TRIGGER FUNCTION].to_set.freeze
            EXEC_OPERATIONS = %w[EXEC EXECUTE CALL].to_set.freeze

            # Additional sets for common lookups
            STOP_COLLECTION_KEYWORDS = %w[WITH SET WHERE BEGIN RESTART START INCREMENT BY].to_set.freeze
            DDL_KEYWORDS = %w[CREATE ALTER].to_set.freeze
            UNION_SELECT_KEYWORDS = %w[UNION SELECT].to_set.freeze
            UNIQUE_KEYWORDS = %w[UNIQUE CLUSTERED DISTINCT].to_set.freeze
            DDL_OPERATIONS = %w[CREATE ALTER].to_set.freeze

            # Shared cache for upcase operations to reduce string allocations
            # Uses original string as key to avoid unnecessary upcasing
            UPCASE_CACHE = {} # rubocop:disable Style/MutableConstant
            private_constant :UPCASE_CACHE

            MAX_SUMMARY_LENGTH = 255

            # Upcase with caching for common SQL keywords to reduce allocations.
            # Check cache first to avoid unnecessary string operations.
            def cached_upcase(str)
              return nil if str.nil?
              return str if str.empty?

              UPCASE_CACHE[str] ||= str.upcase.freeze
            end
            module_function :cached_upcase
          end
        end
      end
    end
  end
end

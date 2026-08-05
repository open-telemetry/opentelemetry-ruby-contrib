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

            TYPE_INDEX = 0
            VALUE_INDEX = 1

            MAIN_OPERATIONS = %w[SELECT INSERT DELETE].to_set.freeze
            COLLECTION_OPERATIONS = %w[WITH].to_set.freeze
            UPDATE_OPERATIONS = %w[UPDATE].to_set.freeze
            TRIGGER_COLLECTION = %w[FROM INTO JOIN IN].to_set.freeze
            TABLE_OPERATIONS = %w[CREATE ALTER DROP TRUNCATE].to_set.freeze
            TABLE_OBJECTS = %w[TABLE INDEX PROCEDURE VIEW DATABASE ROLE USER SCHEMA SEQUENCE TRIGGER FUNCTION].to_set.freeze
            EXEC_OPERATIONS = %w[EXEC EXECUTE CALL].to_set.freeze

            STOP_COLLECTION_KEYWORDS = %w[WITH SET WHERE BEGIN RESTART START INCREMENT BY].to_set.freeze
            DDL_KEYWORDS = %w[CREATE ALTER].to_set.freeze
            UNION_SELECT_KEYWORDS = %w[UNION SELECT].to_set.freeze
            UNIQUE_KEYWORDS = %w[UNIQUE CLUSTERED DISTINCT].to_set.freeze
            DDL_OPERATIONS = %w[CREATE ALTER].to_set.freeze

            MAX_SUMMARY_LENGTH = 255

            CACHE_MUTEX = Mutex.new
            UPCASE_CACHE = {} # rubocop:disable Style/MutableConstant
            MAX_CACHE_SIZE = 1000
            private_constant :UPCASE_CACHE, :CACHE_MUTEX, :MAX_CACHE_SIZE

            def cached_upcase(str)
              return nil if str.nil?
              return str if str.empty?

              cached = UPCASE_CACHE[str]
              return cached if cached

              CACHE_MUTEX.synchronize do
                return UPCASE_CACHE[str] if UPCASE_CACHE.key?(str)

                UPCASE_CACHE.shift if UPCASE_CACHE.size >= MAX_CACHE_SIZE

                UPCASE_CACHE[str] = str.upcase.freeze
              end
            end

            # Allows calling Constants.cached_upcase(str) directly
            module_function :cached_upcase
          end
        end
      end
    end
  end
end

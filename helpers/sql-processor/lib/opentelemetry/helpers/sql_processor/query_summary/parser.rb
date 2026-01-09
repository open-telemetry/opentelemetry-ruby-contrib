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

        # Optimized frozen sets for O(1) lookups instead of O(n) array includes
        MAIN_OPERATIONS = %w[SELECT INSERT DELETE].to_set.freeze
        COLLECTION_OPERATIONS = %w[WITH].to_set.freeze
        UPDATE_OPERATIONS = %w[UPDATE].to_set.freeze
        TRIGGER_COLLECTION = %w[FROM INTO JOIN IN].to_set.freeze
        TABLE_OPERATIONS = %w[CREATE ALTER DROP TRUNCATE].to_set.freeze
        TABLE_OBJECTS = %w[TABLE INDEX PROCEDURE VIEW DATABASE ROLE USER SCHEMA SEQUENCE TRIGGER FUNCTION].to_set.freeze
        EXEC_OPERATIONS = %w[EXEC EXECUTE].to_set.freeze

        # Additional sets for common lookups
        STOP_COLLECTION_KEYWORDS = %w[WITH SET WHERE BEGIN RESTART START INCREMENT BY].to_set.freeze
        DDL_KEYWORDS = %w[CREATE ALTER].to_set.freeze
        UNION_SELECT_KEYWORDS = %w[UNION SELECT].freeze
        UNIQUE_KEYWORDS = %w[UNIQUE CLUSTERED DISTINCT].freeze
        DDL_OPERATIONS = %w[CREATE ALTER].freeze

        # Cache upcase results for common keywords
        UPCASE_CACHE = {} # rubocop:disable Style/MutableConstant
        private_constant :UPCASE_CACHE

        # Maximum length for table names to avoid excessively long summaries
        MAX_TABLE_NAME_LENGTH = 100

        class << self
          # Optimized upcase with caching for common SQL keywords
          def cached_upcase(str)
            return str if str.nil? || str.empty?

            UPCASE_CACHE[str] ||= str.upcase.freeze
          end

          def build_summary_from_tokens(tokens)
            summary_parts = []
            state = PARSING_STATE
            skip_until = 0 # Skip tokens we've already processed when looking ahead
            in_clause_context = false # Track if we're in an IN clause context

            # First pass: check if any table names are too long
            has_long_table_name = tokens.any? { |token| identifier_like?(token) && token[VALUE_INDEX].length > MAX_TABLE_NAME_LENGTH }

            tokens.each_with_index do |token, index|
              next if index < skip_until

              # Update IN clause context
              if cached_upcase(token[VALUE_INDEX]) == 'IN'
                in_clause_context = true
              elsif token[VALUE_INDEX] == '(' && in_clause_context
                # Continue in IN clause context until we find closing parenthesis
              elsif token[VALUE_INDEX] == ')' && in_clause_context
                in_clause_context = false
              end

              result = process_token(token, tokens, index,
                                     state: state,
                                     has_long_table_name: has_long_table_name,
                                     in_clause_context: in_clause_context)

              summary_parts.concat(result[:parts])
              state = result[:new_state]
              skip_until = result[:next_index]
            end

            # Post-process to consolidate UNION queries
            consolidate_union_queries(summary_parts).join(' ')
          end

          def process_token(token, tokens, index, **options)
            state = options[:state]
            has_long_table_name = options[:has_long_table_name] || false
            in_clause_context = options[:in_clause_context] || false

            # In DDL body state, skip all tokens
            return { processed: true, parts: [], new_state: state, next_index: index + 1 } if state == DDL_BODY_STATE

            operation_result = process_main_operation(token, tokens, index,
                                                      state: state,
                                                      in_clause_context: in_clause_context)
            return operation_result if operation_result[:processed]

            collection_result = process_collection_token(token, tokens, index,
                                                         state: state,
                                                         has_long_table_name: has_long_table_name,
                                                         in_clause_context: in_clause_context)
            return collection_result if collection_result[:processed]

            { processed: false, parts: [], new_state: state, next_index: index + 1 }
          end

          def process_main_operation(token, tokens, index, state:, in_clause_context: false)
            # Skip processing main operations when inside IN clause subqueries
            return not_processed(state, index + 1) if in_clause_context

            upcased_value = cached_upcase(token[VALUE_INDEX])

            case upcased_value
            when 'AS'
              # AS in main parsing context might indicate DDL body start
              handle_as_keyword(token, tokens, index, state)
            when *MAIN_OPERATIONS
              add_to_summary(token[VALUE_INDEX], PARSING_STATE, index + 1)
            when *COLLECTION_OPERATIONS
              # Check if this is WITH in OPENJSON context - if so, skip it
              if upcased_value == 'WITH' && index.positive?
                # Optimized lookback - search backwards up to 5 tokens
                start_idx = [0, index - 5].max
                found_openjson = tokens[start_idx...index].any? do |t|
                  cached_upcase(t[VALUE_INDEX]) == 'OPENJSON'
                end

                if found_openjson
                  # This is OPENJSON WITH syntax, not a CTE - skip it
                  return not_processed(state, index + 1)
                end
              end

              add_to_summary(token[VALUE_INDEX], EXPECT_COLLECTION_STATE, index + 1)
            when *UPDATE_OPERATIONS
              handle_update_operation(token, tokens, index)
            when *TRIGGER_COLLECTION
              expect_table_names_next(index + 1)
            when *TABLE_OPERATIONS
              handle_table_operation(token, tokens, index)
            when *EXEC_OPERATIONS
              handle_exec_operation(token, tokens, index)
            when 'UNION'
              handle_union(token, tokens, index)
            else
              not_processed(state, index + 1)
            end
          end

          def process_collection_token(token, tokens, index, **options)
            state = options[:state]
            has_long_table_name = options[:has_long_table_name] || false
            in_clause_context = options[:in_clause_context] || false

            return not_processed(state, index + 1) unless state == EXPECT_COLLECTION_STATE

            upcased_value = cached_upcase(token[VALUE_INDEX])

            # Stop collection when we hit certain keywords that signal the end of the object name
            if upcased_value == 'AS'
              # AS indicates start of DDL body - stop processing everything
              { processed: true, parts: [], new_state: DDL_BODY_STATE, next_index: index + 1 }
            elsif identifier_like?(token) || (token[TYPE_INDEX] == :string && !in_clause_context) || (token[TYPE_INDEX] == :keyword && can_be_table_name?(upcased_value))
              process_table_name_and_alias(token, tokens, index, has_long_table_name: has_long_table_name)
            elsif token[VALUE_INDEX] == '(' || token[TYPE_INDEX] == :operator
              handle_collection_operator(token, state, index)
            else
              # This handles STOP_COLLECTION_KEYWORDS and any other unhandled cases
              return_to_normal_parsing(token, index)
            end
          end

          def process_table_name_and_alias(token, tokens, index, has_long_table_name: false)
            # Special handling for PROCEDURE with AS BEGIN pattern FIRST (before general AS handling)
            # For "CREATE PROCEDURE name AS BEGIN SELECT * FROM table END" we want to extract the inner operations
            if token[VALUE_INDEX].length > 3 # Skip very short names
              # Look for immediate AS BEGIN pattern (PROCEDURE name AS BEGIN...)
              as_token = tokens[index + 1]
              begin_token = tokens[index + 2]

              if as_token && as_token[VALUE_INDEX]&.upcase == 'AS' && begin_token && begin_token[VALUE_INDEX]&.upcase == 'BEGIN'
                # This is a PROCEDURE with AS BEGIN structure - we want to parse the body
                # Continue normal processing but include the procedure name and skip AS BEGIN
                table_parts = has_long_table_name || !should_include_table_name?(token[VALUE_INDEX]) ? [] : [token[VALUE_INDEX]]
                return { processed: true, parts: table_parts, new_state: PARSING_STATE, next_index: index + 3 }
              end
            end

            # Check if the next token is AS in DDL context (not an alias)
            next_token = tokens[index + 1]
            if next_token && next_token[VALUE_INDEX]&.upcase == 'AS'
              # In DDL operations, AS starts the body definition, not an alias
              # Check if this looks like DDL AS (followed by DDL keywords like SELECT, BEGIN, etc.)
              after_as_token = tokens[index + 2]
              if after_as_token && %w[SELECT INSERT UPDATE DELETE BEGIN].include?(after_as_token[VALUE_INDEX].upcase)
                # This is DDL AS - transition to DDL_BODY_STATE and skip AS
                table_parts = has_long_table_name || !should_include_table_name?(token[VALUE_INDEX]) ? [] : [token[VALUE_INDEX]]
                return { processed: true, parts: table_parts, new_state: DDL_BODY_STATE, next_index: index + 2 }
              end
            end

            # For TRIGGER patterns, look ahead for AS keyword after ON/AFTER/BEFORE clauses
            # Handle patterns like: "TRIGGER name ON table AFTER INSERT AS BEGIN"
            if token[VALUE_INDEX].length > 3 # Skip very short names that are likely not real trigger names
              look_ahead_index = index + 1
              found_as_with_begin = false

              # Look ahead up to 10 tokens for AS followed by BEGIN
              while look_ahead_index < tokens.length && look_ahead_index < index + 10
                current_token = tokens[look_ahead_index]
                look_ahead_index += 1
                next unless current_token && current_token[VALUE_INDEX]&.upcase == 'AS'

                next_after_as = tokens[look_ahead_index]
                if next_after_as && next_after_as[VALUE_INDEX]&.upcase == 'BEGIN'
                  found_as_with_begin = true
                  break
                end
              end

              if found_as_with_begin
                # This is a TRIGGER name - transition to DDL_BODY_STATE at the AS token
                table_parts = has_long_table_name || !should_include_table_name?(token[VALUE_INDEX]) ? [] : [token[VALUE_INDEX]]
                return { processed: true, parts: table_parts, new_state: DDL_BODY_STATE, next_index: look_ahead_index + 1 }
              end
            end

            # Regular alias handling for non-DDL cases
            skip_count = calculate_alias_skip(tokens, index)

            # Check what comes after the table name and any aliases
            next_token_after_alias = tokens[index + 1 + skip_count]

            # Stop if we hit certain keywords that end the object name or parameter lists
            should_terminate = false
            # Default state for most cases
            new_state = PARSING_STATE

            if next_token_after_alias && %w[START RESTART].include?(next_token_after_alias[VALUE_INDEX]&.upcase)
              # Handle START WITH and RESTART WITH patterns - check for WITH following
              following_token = tokens[index + 2 + skip_count]
              skip_count += if following_token && following_token[VALUE_INDEX]&.upcase == 'WITH'
                              2 # Skip both keyword and WITH
                            else
                              1 # Skip just the keyword
                            end
            elsif next_token_after_alias && %w[WITH SET WHERE BEGIN DROP ADD COLUMN INCREMENT BY].include?(next_token_after_alias[VALUE_INDEX].upcase)
              # Skip over the stopping keyword so it doesn't get processed again
              skip_count += 1
            elsif next_token_after_alias && next_token_after_alias[VALUE_INDEX] == ','
              # Check if there's a comma - if so, expect more table names in the list
              new_state = EXPECT_COLLECTION_STATE
              skip_count += 1 # Skip the comma
            end

            # Apply truncation logic - if any table name is too long, exclude all table names
            cleaned_table_name = clean_table_name(token[VALUE_INDEX])
            table_parts = has_long_table_name || !should_include_table_name?(cleaned_table_name) ? [] : [cleaned_table_name]

            result = { processed: true, parts: table_parts, new_state: new_state, next_index: index + 1 + skip_count }
            result[:terminate_after_ddl] = true if should_terminate
            result
          end

          def handle_collection_operator(token, state, index)
            { processed: true, parts: [], new_state: state, next_index: index + 1 }
          end

          def return_to_normal_parsing(token, index)
            { processed: true, parts: [], new_state: PARSING_STATE, next_index: index + 1 }
          end

          def return_to_normal_parsing_with_termination(token, index)
            { processed: true, parts: [], new_state: PARSING_STATE, next_index: index + 1, terminate_after_ddl: true }
          end

          def identifier_like?(token)
            %i[identifier quoted_identifier].include?(token[TYPE_INDEX])
          end

          def can_be_table_name?(upcased_value)
            # Object types that can appear after DDL operations
            TABLE_OBJECTS.include?(upcased_value)
          end

          def calculate_alias_skip(tokens, index)
            # Handle both "table AS alias" and "table alias" patterns
            next_token = tokens[index + 1]
            if next_token && next_token[VALUE_INDEX]&.upcase == 'AS'
              2
            elsif next_token && next_token[TYPE_INDEX] == :identifier
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
            if next_token && next_token[VALUE_INDEX]&.upcase == 'ALL'
              { processed: true, parts: ["#{token[VALUE_INDEX]} #{next_token[VALUE_INDEX]}"], new_state: PARSING_STATE, next_index: index + 2 }
            else
              add_to_summary(token[VALUE_INDEX], PARSING_STATE, index + 1)
            end
          end

          def handle_table_operation(token, tokens, index)
            # Handle DDL operations like CREATE, ALTER, DROP
            result = handle_ddl_with_if_exists(token, tokens, index)
            return result if result[:processed]

            # Look ahead to find the object type, skipping modifiers like UNIQUE, CLUSTERED
            object_type_token = nil
            search_index = index + 1

            while search_index < tokens.length
              candidate = tokens[search_index]
              if candidate && TABLE_OBJECTS.include?(candidate[VALUE_INDEX].upcase)
                object_type_token = candidate
                break
              elsif candidate && UNIQUE_KEYWORDS.include?(candidate[VALUE_INDEX].upcase)
                # Skip modifiers
                search_index += 1
              else
                break
              end
            end

            if object_type_token
              { processed: true, parts: ["#{token[VALUE_INDEX]} #{object_type_token[VALUE_INDEX].upcase}"], new_state: EXPECT_COLLECTION_STATE, next_index: search_index + 1 }
            else
              add_to_summary(token[VALUE_INDEX], PARSING_STATE, index + 1)
            end
          end

          def handle_ddl_with_if_exists(token, tokens, index)
            # Handle patterns like "DROP USER IF EXISTS name" or "CREATE TABLE IF NOT EXISTS name"
            operation = token[VALUE_INDEX]

            # Look for patterns:
            # 1. DROP OBJECT_TYPE IF EXISTS name -> DROP OBJECT_TYPE name
            # 2. CREATE TABLE IF NOT EXISTS name -> CREATE TABLE name
            # 3. DROP IF EXISTS object_type name -> DROP object_type name (for sequences, etc)

            # Case 1: DROP OBJECT_TYPE IF EXISTS name
            next_token = tokens[index + 1]
            if next_token && TABLE_OBJECTS.include?(next_token[VALUE_INDEX].upcase)
              object_type = next_token[VALUE_INDEX]
              if tokens[index + 2] && tokens[index + 2][VALUE_INDEX]&.upcase == 'IF' &&
                 tokens[index + 3] && tokens[index + 3][VALUE_INDEX]&.upcase == 'EXISTS'
                object_name = tokens[index + 4]
                return { processed: true, parts: ["#{operation} #{object_type.upcase} #{object_name[VALUE_INDEX]}"], new_state: PARSING_STATE, next_index: index + 5 } if object_name
              end
            end

            # Case 2: CREATE TABLE IF NOT EXISTS name
            if operation.upcase == 'CREATE' && next_token && TABLE_OBJECTS.include?(next_token[VALUE_INDEX].upcase)
              object_type = next_token[VALUE_INDEX]
              if tokens[index + 2] && tokens[index + 2][VALUE_INDEX]&.upcase == 'IF' &&
                 tokens[index + 3] && tokens[index + 3][VALUE_INDEX]&.upcase == 'NOT' &&
                 tokens[index + 4] && tokens[index + 4][VALUE_INDEX]&.upcase == 'EXISTS'
                object_name = tokens[index + 5]
                return { processed: true, parts: ["#{operation} #{object_type.upcase} #{object_name[VALUE_INDEX]}"], new_state: PARSING_STATE, next_index: index + 6 } if object_name
              end
            end

            # No match found
            { processed: false, parts: [], new_state: PARSING_STATE, next_index: index + 1 }
          end

          def handle_exec_operation(token, tokens, index)
            # Handle EXEC/EXECUTE operations - get the procedure name
            next_token = tokens[index + 1]
            if next_token && identifier_like?(next_token)
              { processed: true, parts: ["#{token[VALUE_INDEX]} #{next_token[VALUE_INDEX]}"], new_state: PARSING_STATE, next_index: index + 2 }
            else
              add_to_summary(token[VALUE_INDEX], PARSING_STATE, index + 1)
            end
          end

          def handle_update_operation(token, tokens, index)
            # UPDATE has special rules - check if we should include table name
            # Look ahead to see if there's a parenthesized constant pattern
            table_token = tokens[index + 1]
            set_token = tokens[index + 2]

            if table_token && set_token && set_token[VALUE_INDEX]&.upcase == 'SET'
              # Check if there's a parenthesized constant pattern after SET
              assignment_part = tokens[(index + 3)..-1] || []
              has_parenthesized_constant = assignment_part.any? { |t| t[VALUE_INDEX] == '(' }

              if has_parenthesized_constant && table_token[VALUE_INDEX].length == 1
                # For single-char table names with parenthesized constants, return just UPDATE
                add_to_summary(token[VALUE_INDEX], PARSING_STATE, index + 1)
              else
                # Standard UPDATE with table name
                add_to_summary(token[VALUE_INDEX], EXPECT_COLLECTION_STATE, index + 1)
              end
            else
              # Default UPDATE handling
              add_to_summary(token[VALUE_INDEX], EXPECT_COLLECTION_STATE, index + 1)
            end
          end

          def handle_as_keyword(token, tokens, index, current_state)
            # Check if AS appears after DDL operations by looking at previous tokens
            # Use a larger lookback window to handle complex parameter lists
            recent_tokens = tokens[0...index] || []
            has_ddl_operation = recent_tokens.any? { |t| DDL_OPERATIONS.include?(t[VALUE_INDEX].upcase) }

            if has_ddl_operation
              { processed: true, parts: [], new_state: DDL_BODY_STATE, next_index: index + 1 }
            else
              not_processed(current_state, index + 1)
            end
          end

          def consolidate_union_queries(summary_parts)
            # Convert "SELECT table1 UNION SELECT table2" to "SELECT table1 table2"
            result = []
            i = 0

            while i < summary_parts.length
              current = summary_parts[i]

              if current == 'SELECT' && i + 2 < summary_parts.length
                # Look for SELECT ... UNION SELECT pattern
                [current]

                # Collect table names from first SELECT
                i += 1
                table_names, i = collect_table_names_from_position(summary_parts, i)

                # Process UNION chains
                i = process_union_chain(summary_parts, i, table_names)

                # Add consolidated result
                result << 'SELECT'
                result.concat(table_names)
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

            while i < summary_parts.length && !UNION_SELECT_KEYWORDS.include?(summary_parts[i])
              table_names << summary_parts[i]
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

              next unless i < summary_parts.length && summary_parts[i] == 'SELECT'

              i += 1 # Skip SELECT
              # Collect table names from this SELECT
              additional_names, i = collect_table_names_from_position(summary_parts, i)
              table_names.concat(additional_names)
            end

            i
          end

          def clean_table_name(table_name)
            # Remove SQL Server brackets and MySQL backticks - preserve standard SQL quotes
            case table_name
            when /^\[(.+)\]$/, /^`(.+)`$/
              ::Regexp.last_match(1) # Remove SQL Server brackets [table] or MySQL backticks `table` -> table
            else
              table_name # Preserve double quotes "table" and single quotes 'table'
            end
          end

          def should_include_table_name?(table_name)
            # Skip excessively long table names to avoid cluttering summaries
            table_name.length <= MAX_TABLE_NAME_LENGTH
          end
        end
      end
    end
  end
end

# SQL Query Parser Architecture

This directory contains a modular SQL query parser that generates high-level summaries of SQL queries. The parser transforms tokenized SQL queries into concise summaries like "SELECT users" or "CREATE TABLE orders".

## Overview

The parser uses a **state machine approach** with **explicit module namespacing** to process SQL tokens and extract key operations and table names. It's designed to handle complex SQL patterns including DDL operations, UNION queries, and various SQL dialects.

**Input**: Array of tokens from the tokenizer
**Output**: String summary (e.g., "SELECT users orders" or "CREATE PROCEDURE GetUser")

## Architecture

The parser is split into focused modules, each with specific responsibilities:

```
Parser (Main Orchestrator)
├── Constants (Configuration & State Definitions)
├── TokenProcessor (Core Token Processing Logic)
├── DdlHandler (DDL Pattern Recognition)
├── TableProcessor (Table Name & Alias Handling)
├── OperationHandler (SQL Operation Handlers)
└── SummaryConsolidator (UNION Query Processing)
```

All modules use **explicit namespacing** (e.g., `TokenProcessor.process_token(...)`) for clear code paths and easy maintenance.

## Core Concepts

### State Machine

The parser operates as a state machine with three primary states:

- **`PARSING_STATE`** - Default state looking for SQL operations (SELECT, CREATE, etc.)
- **`EXPECT_COLLECTION_STATE`** - Collecting table names after FROM, INTO, JOIN keywords
- **`DDL_BODY_STATE`** - Inside procedure/trigger bodies; skip all tokens until end

### Token Structure

Tokens are arrays with two elements:
- `Constants::TYPE_INDEX` (0) - Token type (`:keyword`, `:identifier`, `:string`, etc.)
- `Constants::VALUE_INDEX` (1) - Token value (the actual SQL text)

## Module Details

### 1. Constants (`constants.rb`)

**Purpose**: Centralized configuration, state definitions, and optimized keyword lookups.

**Key Responsibilities**:
- State machine constants (`PARSING_STATE`, `EXPECT_COLLECTION_STATE`, `DDL_BODY_STATE`)
- SQL operation sets (`MAIN_OPERATIONS`, `TABLE_OPERATIONS`, etc.)
- Token indices (`TYPE_INDEX`, `VALUE_INDEX`)
- Cached upcase method for performance optimization

**Key Methods**:
- `Constants.cached_upcase(str)` - Optimized string uppercasing with caching

**Example Usage**:
```ruby
if Constants::MAIN_OPERATIONS.include?(upcased_value)
  # Handle SELECT, INSERT, DELETE operations
end
```

### 2. TokenProcessor (`token_processor.rb`)

**Purpose**: Core token processing engine and main dispatch logic.

**Key Responsibilities**:
- Main token processing workflow
- Operation vs. collection token routing
- Basic token classification
- State transitions

**Key Methods**:
- `TokenProcessor.process_token(token, tokens, index, **options)` - Main entry point
- `TokenProcessor.process_main_operation(...)` - Handle SQL operations
- `TokenProcessor.process_collection_token(...)` - Handle table name collection
- `TokenProcessor.add_to_summary(part, new_state, next_index)` - Add parts to result

**Flow**:
1. Check if in DDL_BODY_STATE (skip if true)
2. Try processing as main operation
3. Try processing as collection token
4. Return appropriate state and parts

### 3. DdlHandler (`ddl_handler.rb`)

**Purpose**: Specialized handling for DDL (Data Definition Language) patterns and complex AS constructs.

**Key Responsibilities**:
- Procedure AS BEGIN pattern recognition
- DDL AS pattern detection
- Trigger pattern handling
- Table name and alias processing coordination
- Performance-optimized keyword detection

**Key Methods**:
- `DdlHandler.process_table_name_and_alias(token, tokens, index)` - Main coordination
- `DdlHandler.handle_procedure_as_begin_pattern(...)` - Detect "PROCEDURE name AS BEGIN"
- `DdlHandler.handle_ddl_as_pattern(...)` - Handle DDL AS constructs
- `DdlHandler.handle_trigger_as_begin_pattern(...)` - Process trigger definitions

**Performance Features**:
- `DDL_BODY_START_KEYWORDS` - Optimized hash lookup for keywords that start DDL bodies
- Consistent use of `Constants.cached_upcase` for performance
- Improved bounds checking for token access

**Example Patterns Handled**:
- `CREATE PROCEDURE GetUser AS BEGIN SELECT * FROM users END`
- `CREATE TRIGGER UpdateAudit ON users AFTER INSERT AS BEGIN ... END`
- `CREATE VIEW UserView AS SELECT * FROM users`

### 4. TableProcessor (`table_processor.rb`)

**Purpose**: Table name extraction, alias resolution, and state management after table identification.

**Key Responsibilities**:
- Clean table names (remove SQL Server brackets, MySQL backticks)
- Handle table aliases (`table AS alias`, `table alias`)
- Determine next parser state after table processing
- Special pattern handling (START WITH, RESTART WITH)
- Performance-optimized state transitions

**Key Methods**:
- `TableProcessor.handle_regular_table_name(token, tokens, index)` - Main table processing
- `TableProcessor.clean_table_name(table_name)` - Remove formatting characters with bounds checking
- `TableProcessor.calculate_alias_skip(tokens, index)` - Skip alias tokens
- `TableProcessor.determine_next_state_after_table(...)` - State transition logic

**Performance Features**:
- `STOP_KEYWORDS` - Hash-based lookup for keywords that end table collection
- Optimized `clean_table_name` with bounds checking to prevent unnecessary operations
- Consistent use of `Constants.cached_upcase` throughout

**Table Cleaning Examples**:
- `[users]` → `users` (SQL Server brackets removed)
- `` `orders` `` → `orders` (MySQL backticks removed)
- `"customers"` → `"customers"` (Standard SQL quotes preserved)

### 5. OperationHandler (`operation_handler.rb`)

**Purpose**: Specialized handlers for different SQL operations and their unique patterns.

**Key Responsibilities**:
- UNION and UNION ALL processing
- DDL operations (CREATE, ALTER, DROP) with modifiers
- EXEC/EXECUTE/CALL procedure handling
- UPDATE operation special cases
- AS keyword context detection

**Key Methods**:
- `OperationHandler.handle_union(token, tokens, index)` - Process UNION operations
- `OperationHandler.handle_table_operation(...)` - Handle CREATE/ALTER/DROP
- `OperationHandler.handle_exec_operation(...)` - Process stored procedure calls
- `OperationHandler.handle_update_operation(...)` - Handle UPDATE with special rules
- `OperationHandler.handle_ddl_with_if_exists(...)` - Process IF EXISTS patterns

**Special Cases Handled**:
- `DROP TABLE IF EXISTS users` → `DROP TABLE users`
- `CREATE TABLE IF NOT EXISTS orders` → `CREATE TABLE orders`
- `EXEC GetUserData @userId = 1` → `EXEC GetUserData`
- `UNION ALL SELECT` → `UNION ALL`

### 6. SummaryConsolidator (`summary_consolidator.rb`)

**Purpose**: Post-processing to consolidate UNION queries into cleaner summaries.

**Key Responsibilities**:
- Detect UNION query chains
- Merge table names from multiple SELECT statements
- Preserve operation structure while reducing redundancy
- Prevent duplicate table names in self-unions

**Key Methods**:
- `SummaryConsolidator.consolidate_union_queries(summary_parts)` - Main consolidation
- `SummaryConsolidator.collect_table_names_from_position(...)` - Extract table names
- `SummaryConsolidator.process_union_chain(...)` - Process UNION sequences

**Advanced Features**:
- Uses `Constants` operation sets for consistent keyword detection
- Applies `.uniq` to prevent duplicates like "SELECT users users" in self-unions
- Robust handling of incomplete UNION chains

**Consolidation Examples**:
- Input: `["SELECT", "users", "UNION", "SELECT", "orders"]`
- Output: `["SELECT", "users", "orders"]`
- Self-union: `["SELECT", "users", "UNION", "SELECT", "users"]`
- Output: `["SELECT", "users"]` (duplicate removed)


## Processing Flow

### 1. Main Processing Loop (Parser.build_summary_from_tokens)

```ruby
def build_summary_from_tokens(tokens)
  summary_parts = []
  state = Constants::PARSING_STATE
  skip_until = 0
  in_clause_context = false

  tokens.each_with_index do |token, index|
    # Skip processed tokens
    next if index < skip_until

    # Track IN clause context for subqueries
    # ... context tracking logic ...

    # Process current token
    result = TokenProcessor.process_token(token, tokens, index,
                                         state: state,
                                         in_clause_context: in_clause_context)

    # Accumulate results
    summary_parts.concat(result[:parts])
    state = result[:new_state]
    skip_until = result[:next_index]
  end

  # Post-process and finalize
  summary = SummaryConsolidator.consolidate_union_queries(summary_parts).join(' ')
  truncate_summary(summary)
end
```

### 2. Token Processing Decision Tree

```
TokenProcessor.process_token()
├── In DDL_BODY_STATE? → Skip token
├── Try Main Operation Processing
│   ├── SELECT/INSERT/DELETE → Add to summary, continue parsing
│   ├── CREATE/ALTER/DROP → Delegate to OperationHandler
│   ├── UPDATE → Special handling in OperationHandler
│   ├── UNION → Handle in OperationHandler
│   ├── FROM/INTO/JOIN → Expect table names next
│   └── AS → Check context in OperationHandler
└── Try Collection Token Processing
    ├── In EXPECT_COLLECTION_STATE?
    ├── Identifier/String → Process via DdlHandler
    ├── AS → Transition to DDL_BODY_STATE
    └── Other → Return to PARSING_STATE
```

### 3. DDL Pattern Recognition Flow

```
DdlHandler.process_table_name_and_alias()
├── Try Procedure AS BEGIN Pattern
│   └── "name AS BEGIN" → Include name, skip to body
├── Try DDL AS Pattern
│   └── "name AS SELECT/INSERT..." → Include name, skip body
├── Try Trigger AS BEGIN Pattern
│   └── "name ... AS BEGIN" → Include name, skip body
└── Fallback to Regular Table Processing
    └── TableProcessor.handle_regular_table_name()
```

## Example Processing Walkthrough

Let's trace through processing `"SELECT * FROM users u UNION SELECT * FROM orders"`:

### Step 1: Tokenization (done before parser)
```
[[:keyword, "SELECT"], [:operator, "*"], [:keyword, "FROM"],
 [:identifier, "users"], [:identifier, "u"], [:keyword, "UNION"],
 [:keyword, "SELECT"], [:operator, "*"], [:keyword, "FROM"],
 [:identifier, "orders"]]
```

### Step 2: Token Processing

1. **"SELECT"** - `TokenProcessor.process_main_operation()`
   - Matches `Constants::MAIN_OPERATIONS`
   - Adds "SELECT" to summary_parts: `["SELECT"]`
   - State remains `PARSING_STATE`

2. **"*"** - No matches, state continues

3. **"FROM"** - `TokenProcessor.process_main_operation()`
   - Matches `Constants::TRIGGER_COLLECTION`
   - State changes to `EXPECT_COLLECTION_STATE`

4. **"users"** - `TokenProcessor.process_collection_token()`
   - In `EXPECT_COLLECTION_STATE`, identifier detected
   - `DdlHandler.process_table_name_and_alias()` called
   - No DDL patterns, goes to `TableProcessor.handle_regular_table_name()`
   - Cleans name: "users" → "users"
   - Adds "users" to summary_parts: `["SELECT", "users"]`

5. **"u"** - Detected as alias, skipped during table processing

6. **"UNION"** - `TokenProcessor.process_main_operation()`
   - `OperationHandler.handle_union()` called
   - Adds "UNION" to summary_parts: `["SELECT", "users", "UNION"]`

7. **"SELECT"** - Processed same as step 1
   - Summary_parts: `["SELECT", "users", "UNION", "SELECT"]`

8. **"FROM", "orders"** - Processed similar to steps 3-4
   - Final summary_parts: `["SELECT", "users", "UNION", "SELECT", "orders"]`

### Step 3: Post-Processing

1. **Union Consolidation** - `SummaryConsolidator.consolidate_union_queries()`
   - Detects "SELECT ... UNION SELECT ..." pattern
   - Consolidates to: `["SELECT", "users", "orders"]`

2. **Final Summary** - `truncate_summary()` (private method in Parser)
   - Joins with spaces: `"SELECT users orders"`
   - Length OK, no truncation needed

**Final Result**: `"SELECT users orders"`

## State Transitions

### Normal Flow
```
PARSING_STATE
    ↓ (FROM/INTO/JOIN/table operation)
EXPECT_COLLECTION_STATE
    ↓ (table found, comma continues / WHERE/SET/other stops)
PARSING_STATE
```

### DDL Flow
```
PARSING_STATE
    ↓ (CREATE PROCEDURE/TRIGGER)
EXPECT_COLLECTION_STATE
    ↓ (procedure name found)
EXPECT_COLLECTION_STATE
    ↓ (AS detected in DDL context)
DDL_BODY_STATE (skip until end)
```

## Performance Optimizations

The parser includes several performance optimizations:

### Hash-Based Keyword Lookups
- `DdlHandler::DDL_BODY_START_KEYWORDS` - O(1) lookup for DDL body start detection
- `TableProcessor::STOP_KEYWORDS` - O(1) lookup for table collection termination
- `Constants` operation sets use `.to_set.freeze` for O(1) membership testing

### Caching & Efficiency
- `Constants.cached_upcase(str)` - Caches uppercased strings to avoid repeated operations
- Bounds checking in `TableProcessor.clean_table_name` prevents unnecessary string operations
- Consistent use of cached upcase throughout all modules

### Smart Processing
- Early termination in DDL body state skips unnecessary token processing
- Duplicate removal in `SummaryConsolidator` prevents redundant table names
- Optimized token lookahead with configurable limits

## Extension Points

To extend the parser:

1. **New SQL Operations** - Add to appropriate operation sets in `Constants`
2. **New DDL Patterns** - Add handlers in `DdlHandler`
3. **Special Processing** - Add methods to `OperationHandler`
4. **Post-Processing** - Extend `SummaryConsolidator` or add methods to `Parser`

## Testing

The parser is thoroughly tested with 119 test cases covering:
- Basic SQL operations (SELECT, INSERT, UPDATE, DELETE)
- Complex DDL patterns (procedures, triggers, views)
- UNION query consolidation
- Edge cases and error conditions
- Performance optimizations

# SQL Query Summary Parser

This directory contains a SQL query parser that converts tokenized SQL statements into summaries.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [State Machine](#state-machine)
- [Module Reference](#module-reference)
- [Processing Flow](#processing-flow)
- [Key Concepts](#key-concepts)
- [Database and SQL Terminology](#database-and-sql-terminology)

## Overview

The parser takes an array of tokens and produces a human-readable summary by:

1. **Identifying SQL operations** (SELECT, INSERT, CREATE, etc.)
2. **Extracting table names** from FROM, JOIN, INTO clauses
3. **Handling complex patterns** like DDL procedures, UNION queries, and aliases
4. **Consolidating results** into clean, deduplicated summaries

**Example:**
```ruby
tokens = [Token.new(:keyword, "SELECT"), Token.new(:identifier, "users")]
Parser.build_summary_from_tokens(tokens) # => "SELECT users"
```

## Architecture

The parser uses a modular architecture where the main `Parser` class extends several specialized modules:

```text
Parser (main entry point)
├── Constants          # Configuration and cached operations
├── TokenProcessor     # Token routing and orchestration
├── OperationHandler   # Specific SQL operation handling
├── DdlHandler         # DDL constructs (procedures, triggers)
├── TableProcessor     # Table name extraction and aliases
└── SummaryConsolidator # Post-processing for UNION queries
```

This design provides:
- **Separation of concerns** - each module has a specific responsibility
- **Maintainability** - changes to one operation type don't affect others
- **Performance** - optimized token processing with minimal object allocation

## State Machine

The parser operates using a three-state finite state machine to track parsing context:

### States

**`PARSING_STATE` (default)**
- Looking for SQL operations (SELECT, CREATE, etc.)
- Processing main query structure
- Transitions to `EXPECT_COLLECTION_STATE` when encountering table-related keywords

**`EXPECT_COLLECTION_STATE`**
- Actively collecting table names after FROM, INTO, JOIN keywords
- Handles table aliases and comma-separated table lists
- Returns to `PARSING_STATE` when hitting WHERE, SET, or other stop keywords

**`DDL_BODY_STATE`**
- Skipping content inside DDL procedure/trigger bodies
- Entered when processing CREATE PROCEDURE ... AS BEGIN patterns
- Stays in this state until end of input (DDL bodies are ignored)

### State Transitions

```text
PARSING_STATE → EXPECT_COLLECTION_STATE
  Triggers: FROM, INTO, JOIN, main operations

EXPECT_COLLECTION_STATE → PARSING_STATE
  Triggers: WHERE, SET, stop keywords

EXPECT_COLLECTION_STATE → DDL_BODY_STATE
  Triggers: AS BEGIN (procedure/trigger body)
```

## Module Reference

### Constants (`constants.rb`)

**Purpose:** Configuration values, operation categorization, and performance optimizations.

**Key Features:**
- **Operation Sets:** Groups SQL keywords by purpose (MAIN_OPERATIONS, TABLE_OPERATIONS, etc.)
- **State Definitions:** The three parser states and their constants
- **Performance Cache:** Thread-safe upcase string cache with LRU eviction
- **Token Indices:** Constants for accessing token array elements

**Important Constants:**
- `MAIN_OPERATIONS`: Core query operations (SELECT, INSERT, DELETE)
- `TABLE_OPERATIONS`: DDL operations (CREATE, ALTER, DROP, TRUNCATE)
- `DDL_KEYWORDS`: Keywords that can start DDL statements
- `MAX_SUMMARY_LENGTH`: 255 character limit for summaries

### TokenProcessor (`token_processor.rb`)

**Purpose:** Central orchestrator that routes tokens to appropriate handlers based on current state.

**Key Functions:**
- **`process_token()`**: Main entry point that determines how to handle each token
- **`process_main_operation()`**: Handles SQL operation keywords
- **`process_collection_token()`**: Processes tokens during table collection phase

**Processing Logic:**
1. Skip all tokens if in `DDL_BODY_STATE`
2. Try to process as main operation (SELECT, CREATE, etc.)
3. If in collection state, handle as table name or collection control
4. Delegate complex patterns to specialized handlers

**Special Handling:**
- **IN clause context**: Avoids misidentifying values in IN clauses as table names
- **OPEN JSON WITH**: Special case for SQL Server's OPEN JSON syntax
- **String tokens**: Can be treated as table names when not in IN clauses

### OperationHandler (`operation_handler.rb`)

**Purpose:** Specialized handlers for specific SQL operations and complex patterns.

**Key Handlers:**

**`handle_union()`**
- Processes UNION and UNION ALL operations
- Looks ahead for ALL keyword and combines them

**`handle_table_operation()`**
- Handles DDL operations like CREATE TABLE, DROP INDEX
- Processes IF EXISTS and IF NOT EXISTS patterns
- Skips modifier keywords like UNIQUE, CLUSTERED

**`handle_update_operation()`**
- Special logic for UPDATE statements with SET clauses
- Detects parenthesized constants to avoid false table detection

**`handle_exec_operation()`**
- Processes EXEC, EXECUTE, CALL statements
- Extracts procedure/function names

**`handle_as_keyword()`**
- Determines if AS keyword starts a DDL body
- Transitions to DDL_BODY_STATE for procedure definitions

### DdlHandler (`ddl_handler.rb`)

**Purpose:** Handles DDL (Data Definition Language) constructs, particularly procedures and triggers.

> **What is DDL?** Data Definition Language includes SQL statements that define database structure: CREATE, ALTER, DROP. Unlike DML (Data Manipulation Language) which works with data, DDL modifies schema objects like tables, procedures, and triggers.

**Key Patterns:**

**Procedure AS BEGIN Pattern**
```sql
CREATE PROCEDURE MyProc AS BEGIN ... END
```
- Keeps procedure name in summary
- Continues parsing to see procedure body content

**DDL AS Pattern**
```sql
CREATE VIEW MyView AS SELECT ...
```
- Keeps object name but skips the body definition
- Transitions to DDL_BODY_STATE

**Trigger AS BEGIN Pattern**
```sql
CREATE TRIGGER MyTrigger ... AS BEGIN ... END
```
- Uses look-ahead to find AS BEGIN pattern up to 10 tokens away
- Skips entire trigger body

### TableProcessor (`table_processor.rb`)

**Purpose:** Extracts and processes table names, handles aliases, and manages state transitions.

**Core Functions:**

**`handle_regular_table_name()`**
- Main entry point for table name processing
- Calculates alias skipping and determines next state
- Cleans quoted table names (removes brackets, backticks)

**`calculate_alias_skip()`**
- Determines how many tokens to skip for aliases
- Handles both explicit (AS alias) and implicit (table alias) forms

**`determine_next_state_after_table()`**
- Decides whether to continue collecting table names or return to normal parsing
- Handles comma-separated table lists
- Processes RESTART/START WITH patterns for sequences

**Table Name Cleaning:**
- Removes SQL Server brackets: `[table_name]` → `table_name`
- Removes MySQL backticks: `` `table_name` `` → `table_name`

**State Management:**
- Comma (`,`) → Stay in EXPECT_COLLECTION_STATE (more tables coming)
- Stop keywords (WHERE, SET) → Return to PARSING_STATE
- Other tokens → Return to PARSING_STATE

### SummaryConsolidator (`summary_consolidator.rb`)

**Purpose:** Post-processing to consolidate UNION queries and clean up the final summary.

**Key Function: `consolidate_union_queries()`**

Transforms:
```ruby
["SELECT", "users", "UNION", "SELECT", "orders", "UNION", "ALL", "SELECT", "users"]
```

Into:
```ruby
["SELECT", "users", "orders"]  # Note: duplicates removed
```

**Processing Logic:**
1. Scan summary parts for SELECT statements
2. Collect all table names following each SELECT
3. Follow UNION/UNION ALL chains to gather all related tables
4. Deduplicate table names (prevents "SELECT users users")
5. Produce consolidated summary

**Chain Processing:**
- Handles complex patterns: `SELECT ... UNION SELECT ... UNION ALL SELECT ...`
- Stops chain processing when encountering non-SELECT operations
- Preserves other operation types unchanged

## Processing Flow

### Main Processing Pipeline

1. **Initialization** (`Parser.build_summary_from_tokens`)
   - Pre-allocate summary parts array for performance
   - Initialize parsing state and context flags
   - Set up token skip tracking for look-ahead processing

2. **Token Processing Loop**
   ```ruby
   tokens.each_with_index do |token, index|
     # Skip if we've already processed this token via look-ahead
     next if index < skip_until

     # Update IN clause context
     # Process token through TokenProcessor
     # Accumulate summary parts and update state
   end
   ```

3. **Post-Processing**
   - Consolidate UNION queries via SummaryConsolidator
   - Truncate summary if it exceeds MAX_SUMMARY_LENGTH
   - Return final summary string

### Token Decision Tree

```text
Token Received
├── In DDL_BODY_STATE? → Skip token
├── Main Operation? → Add to summary, change state
│   ├── SELECT/INSERT/DELETE → PARSING_STATE
│   ├── CREATE/ALTER/DROP → Look for table object
│   ├── UPDATE → Special SET clause handling
│   └── UNION → Handle UNION ALL pattern
├── Collection State?
│   ├── Table-like token → Extract name, handle aliases
│   ├── AS keyword → Check for DDL body transition
│   ├── Comma → Stay in collection state
│   └── Stop keyword → Return to parsing state
└── Other → Continue processing
```

### Error Handling and Edge Cases

**Malformed Queries:** Parser continues processing and produces best-effort summaries

**Token Look-ahead:** Uses `skip_until` index to avoid reprocessing tokens consumed by look-ahead operations

**Memory Efficiency:** Pre-allocates arrays and uses string caching to minimize garbage collection

## Key Concepts

### SQL Operation Types

**DML (Data Manipulation Language)**
- SELECT: Query data from tables
- INSERT: Add new rows to tables
- UPDATE: Modify existing rows
- DELETE: Remove rows from tables

**DDL (Data Definition Language)**
- CREATE: Define new database objects (tables, procedures, etc.)
- ALTER: Modify existing objects
- DROP: Remove objects
- TRUNCATE: Remove all data from table

**DCL (Data Control Language)**
- Not actively parsed, but EXEC/CALL statements are handled

### Performance Considerations

**String Caching:** The `cached_upcase()` function prevents repeated string allocations for common SQL keywords

**Array Pre-allocation:** Summary parts array is pre-sized to reduce memory reallocations

**Look-ahead Optimization:** Complex patterns use bounded look-ahead to avoid processing entire token arrays

**State Machine:** Finite states minimize unnecessary processing by focusing on relevant tokens

### Common SQL Patterns Handled

**Table Aliases:**
```sql
SELECT * FROM users u WHERE u.id = 1
-- Summary: "SELECT users"
```

**Multiple Tables:**
```sql
SELECT * FROM users, orders WHERE users.id = orders.user_id
-- Summary: "SELECT users orders"
```

**UNION Queries:**
```sql
SELECT * FROM users UNION SELECT * FROM admins
-- Summary: "SELECT users admins"
```

**DDL with Bodies:**
```sql
CREATE PROCEDURE GetUser AS BEGIN SELECT * FROM users END
-- Summary: "CREATE PROCEDURE GetUser"
```

**Complex DDL:**
```sql
CREATE TABLE users (id INT, name VARCHAR(50))
-- Summary: "CREATE TABLE users"
```

## Database and SQL Terminology

This section explains database and SQL concepts used throughout the parser for engineers who may not be familiar with database systems.

### SQL Language Categories

**DDL (Data Definition Language)**
- SQL statements that define and modify database structure
- Examples: CREATE, ALTER, DROP, TRUNCATE
- Creates/modifies schema objects like tables, indexes, procedures
- Often contains complex bodies (like procedure definitions) that need special handling

**DML (Data Manipulation Language)**
- SQL statements that work with data inside tables
- Examples: SELECT, INSERT, UPDATE, DELETE
- These are the most common operations in application queries
- Focus on retrieving or modifying table contents

**DCL (Data Control Language)**
- SQL statements that control access and permissions
- Examples: GRANT, REVOKE, EXEC/EXECUTE
- Less commonly parsed, but EXEC statements are handled for stored procedures

### Database Objects

**Table**
- Primary data storage structure with rows and columns
- Most queries target tables: `SELECT * FROM users`

**View**
- Virtual table based on query results
- Created with: `CREATE VIEW user_summary AS SELECT ...`

**Index**
- Performance optimization structure for faster queries
- Created with: `CREATE INDEX idx_name ON table (column)`

**Procedure/Function**
- Stored executable code blocks
- Created with: `CREATE PROCEDURE name AS BEGIN ... END`
- Can have complex bodies that the parser needs to skip

**Trigger**
- Code that automatically executes on table changes
- Created with: `CREATE TRIGGER name ... AS BEGIN ... END`
- Often has complex AS BEGIN patterns

**Schema/Database**
- Container for organizing database objects
- Created with: `CREATE DATABASE name` or `CREATE SCHEMA name`

### SQL Query Components

**Clause**
- Specific parts of SQL statements (FROM, WHERE, GROUP BY, etc.)
- Parser tracks these to understand query structure

**Table Alias**
- Short names for tables in queries
- `SELECT * FROM users u` (u is alias for users)
- Can be explicit (`users AS u`) or implicit (`users u`)

**Subquery**
- Query nested inside another query
- `SELECT * FROM (SELECT id FROM users) subq`

**UNION**
- Combines results from multiple SELECT statements
- `SELECT * FROM users UNION SELECT * FROM admins`
- Parser consolidates these into single summaries

### Token Types

**Keyword**
- Reserved SQL words (SELECT, FROM, WHERE, etc.)
- Parser categorizes these into operation sets

**Identifier**
- Names of tables, columns, variables, etc.
- Usually table/column names in queries

**Quoted Identifier**
- Identifiers wrapped in quotes/brackets
- `[table_name]`, `` `table_name` ``, `"table_name"`

**String**
- Literal string values in quotes
- Can sometimes be confused with table names in certain contexts

**Operator**
- Symbols like `=`, `>`, `+`, `,`, `(`, `)`
- Commas are important for detecting multiple tables

### Parsing Concepts

**Lexer/Tokenizer**
- Breaks SQL text into individual tokens (words, symbols, etc.)
- Runs before the parser - provides the token array input

**Look-ahead**
- Examining future tokens without processing them
- Used for patterns like "CREATE TABLE IF NOT EXISTS"

**State Machine**
- Parser mode that determines how to interpret tokens
- Prevents misidentifying tokens in wrong contexts

**Context Sensitivity**
- Same token can mean different things in different contexts
- Example: identifier could be table name or alias depending on position

**Summary Consolidation**
- Post-processing to clean up and combine related operations
- Especially important for UNION queries with multiple tables

### Common SQL Patterns

**IN Clause**
- `WHERE column IN (value1, value2, value3)`
- Parser must avoid treating values as table names

**JOIN Operations**
- `FROM table1 JOIN table2 ON condition`
- Parser extracts both table names

**SET Clauses**
- `UPDATE table SET column = value`
- Signals end of table name collection

**Conditional DDL**
- `CREATE TABLE IF NOT EXISTS name`
- `DROP TABLE IF EXISTS name`
- Requires look-ahead to parse correctly

**Stored Procedure Bodies**
- Complex blocks of code inside procedures/triggers
- Parser skips these bodies since they're not part of the main operation

This terminology reference helps decode the technical language used throughout the parser implementation and provides context for understanding SQL query structures.

This parser provides a robust foundation for SQL query analysis while maintaining high performance and handling the complexity of real-world SQL statements.
# Query Summary Module

The query summary module transforms SQL queries into high-level summaries for OpenTelemetry span attributes.

```ruby
cache = OpenTelemetry::Helpers::QuerySummary::Cache.new(size: 1000)

summary = OpenTelemetry::Helpers::QuerySummary.generate_summary(
  "SELECT * FROM users WHERE id = 1",
  cache: cache
)
puts summary  # => "SELECT users"

query = "SELECT u.name FROM users u JOIN orders o ON u.id = o.user_id"
summary = OpenTelemetry::Helpers::QuerySummary.generate_summary(query, cache: cache)
puts summary  # => "SELECT users orders"
```

## Examples

| Input SQL | Output Summary |
| --------- | -------------- |
| `SELECT * FROM users WHERE id = 1` | `SELECT users` |
| `INSERT INTO orders VALUES (1, 2, 3)` | `INSERT orders` |
| `CREATE TABLE products (id INT)` | `CREATE TABLE products` |
| `EXEC GetUserStats @userId = 123` | `EXEC GetUserStats` |
| `CALL update_user_profile(456, 'new@email.com')` | `CALL update_user_profile` |
| `SELECT * FROM table1 UNION SELECT * FROM table2` | `SELECT table1 table2` |

## Complex Examples

| Complex SQL | Summary | Why Useful |
| ----------- | ------- | ---------- |
| `SELECT u.*, p.name FROM users u LEFT JOIN profiles p ON u.id=p.user_id WHERE u.created_at > '2023-01-01' AND p.active = 1` | `SELECT users profiles` | Shows JOIN handling, removes sensitive data |
| `INSERT INTO audit_logs (user_id, action, details, created_at) VALUES (?, ?, ?, NOW())` | `INSERT audit_logs` | Removes parameter placeholders |
| `CREATE PROCEDURE update_user(id INT) AS BEGIN UPDATE users SET last_seen=NOW() WHERE id=id; END` | `CREATE PROCEDURE update_user` | Handles stored procedures |
| `CALL generate_monthly_report(2023, 12, 'summary', @user_id)` | `CALL generate_monthly_report` | Stored procedure calls with parameters removed |
| `SELECT * FROM users UNION SELECT * FROM customers` | `SELECT users customers` | UNION queries consolidated (table names merged) |
| `SELECT * FROM orders UNION ALL SELECT * FROM returns` | `SELECT orders UNION ALL SELECT returns` | UNION ALL preserved (not consolidated like regular UNION) |
| `WITH recent AS (SELECT * FROM orders WHERE date > ?) SELECT r.*, u.name FROM recent r JOIN users u` | `WITH recent SELECT orders SELECT recent users` | Handles CTEs and subqueries |
| `UPDATE users SET status = 'active' WHERE id IN (1,2,3,4,5)` | `UPDATE users` | Removes literal values |
| `DELETE FROM sessions WHERE expires_at < NOW() AND user_id = ?` | `DELETE sessions` | Removes sensitive conditions |

## Configuration

Each instrumentation creates its own cache instance:

```ruby
pg_cache = OpenTelemetry::Helpers::QuerySummary::Cache.new(size: 2000)

summary = OpenTelemetry::Helpers::QuerySummary.generate_summary(query, cache: pg_cache)
```

**Configuration in OpenTelemetry instrumentations:**
```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::PG', {
    query_summary_cache_size: 5000,
    query_summary_enabled: true
  }
end
```

## Architecture

The module uses a three-stage pipeline to transform SQL queries into summaries:

```text
SQL Query → Tokenizer → Parser → Summary
                              ↕
                           Cache (stores results)
```

## Tokenizer Details

Breaks SQL strings into structured tokens using `StringScanner` for parsing.

**Example:**
```ruby
"SELECT * FROM users WHERE id = 1"

[
  [:keyword, "SELECT"],
  [:operator, "*"],
  [:keyword, "FROM"],
  [:identifier, "users"],
  [:keyword, "WHERE"],
  [:identifier, "id"],
  [:operator, "="],
  [:numeric, "1"]
]
```

**Token Types:**
- `:keyword` - SQL keywords (SELECT, FROM, WHERE, EXEC, EXECUTE, CALL, CREATE, etc.)
- `:identifier` - Table/column names, procedure names
- `:quoted_identifier` - Quoted names (`table`, [table], "table")
- `:operator` - SQL operators (=, <, >, +, -, *, (, ), ;)
- `:numeric` - Numbers (integers, decimals, scientific notation, hex)
- `:string` - String literals (automatically filtered for privacy)

## Parser Details

Uses a **finite state machine** with three states to extract operations and table names from tokens.

### Parser State Flow
```text
SQL Token → PARSING → FROM/JOIN → EXPECT_COLLECTION → table names
                ↓           ↓              ↓
            Operations   WHERE/END    Back to PARSING
                ↓
         AS BEGIN → DDL_BODY (skip everything)
```

**States:**
- **PARSING** - Default state, looking for SQL operations (SELECT, CREATE, EXEC, CALL, etc.)
- **EXPECT_COLLECTION** - Collecting table names after FROM, INTO, JOIN
- **DDL_BODY** - Inside stored procedures/triggers, skips all tokens

**Process:**
1. Process tokens sequentially with finite state machine
2. Apply state transitions based on SQL keywords
3. Collect operations and table names with lookahead for complex patterns
4. Consolidate UNION queries in post-processing
5. Truncate final summary at 255 characters (OpenTelemetry spec compliance)

## Cache Details

LRU cache that stores generated summaries to avoid reprocessing identical queries.

**Features:**
- Default size: 1000 entries
- Mutex synchronization for thread safety
- LRU eviction: oldest entries removed when cache reaches size limit
- `fetch(key) { block }` interface

**Behavior:**
- Cache hits return stored values without executing the block
- Cache misses execute the block and store the result
- When resizing to a smaller size, cache is cleared completely

## Integration

Each database instrumentation needs two new configuration options: `query_summary_cache_size` and `query_summary_enabled`. 

```ruby
class Instrumentation < OpenTelemetry::Instrumentation::Base
  option :query_summary_cache_size, default: 1000, validate: :integer
  option :query_summary_enabled, default: true, validate: :boolean

  install do |config|
    require_dependencies
    initialize_query_summary_cache(config) if config[:query_summary_enabled]
    patch_client
  end

  class << self
    attr_reader :query_summary_cache
  end

  private

  def initialize_query_summary_cache(config)
    require 'opentelemetry-helpers-sql-processor'
    self.class.instance_variable_set(
      :@query_summary_cache,
      OpenTelemetry::Helpers::QuerySummary::Cache.new(size: config[:query_summary_cache_size])
    )
  rescue LoadError
    OpenTelemetry.logger.debug('Query summary helper not available')
  end
end
```
Query summary will be used to generate the `db.query.summary` attribute. This is a recommended attribute that should be a span's name, if `db.query.summary` is available.

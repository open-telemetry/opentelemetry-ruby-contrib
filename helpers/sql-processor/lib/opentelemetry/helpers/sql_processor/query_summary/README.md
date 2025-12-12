# Query Summary Module

Generates concise summaries of SQL queries for OpenTelemetry telemetry, removing sensitive data while preserving operations and table names.

# Basic usage
summary = OpenTelemetry::Helpers::QuerySummary.generate_summary("SELECT * FROM users WHERE id = 1")
puts summary  # => "SELECT users"

# Complex queries
query = "SELECT u.name FROM users u JOIN orders o ON u.id = o.user_id"
summary = OpenTelemetry::Helpers::QuerySummary.generate_summary(query)
puts summary  # => "SELECT users orders"
```

## Examples

| Input SQL | Output Summary |
|-----------|----------------|
| `SELECT * FROM users WHERE id = 1` | `SELECT users` |
| `INSERT INTO orders VALUES (1, 2, 3)` | `INSERT orders` |
| `CREATE TABLE products (id INT)` | `CREATE TABLE products` |
| `SELECT ... UNION SELECT ...` | `SELECT table1 table2` |

## How It Works

1. **Tokenization** - Breaks SQL into keywords, identifiers, and operators
2. **Parsing** - Uses a state machine to identify operations and table names
3. **Caching** - Thread-safe LRU cache for performance

## Configuration

```ruby
# Configure cache size (default: 1000)
OpenTelemetry::Helpers::QuerySummary.configure_cache(size: 500)
```

## Integration

Used by OpenTelemetry database instrumentations (pg, mysql2, trilogy) to set the `db.query.summary` span attribute for safe telemetry without exposing sensitive data.
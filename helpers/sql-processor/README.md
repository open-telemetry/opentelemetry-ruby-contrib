# OpenTelemetry Instrumentation Helpers: SQL Processor

This Ruby gem provides comprehensive SQL processing utilities for OpenTelemetry instrumentation, including **SQL obfuscation** and **high-performance query summarization**. It's designed for gem authors instrumenting SQL adapter libraries such as mysql2, pg, trilogy, and others.

## Features

- **🔒 SQL Obfuscation**: Remove sensitive data from SQL queries
- **⚡ Query Summarization**: Generate concise, high-level summaries of SQL queries
- **🚀 High Performance**: Optimized with fast-path patterns and intelligent caching
- **🧵 Thread Safe**: All components are designed for concurrent usage
- **🎯 Production Ready**: 99.6%+ test coverage with comprehensive benchmarks

## Installation

Add the gem to your instrumentation's gemspec file:

```ruby
# opentelemetry-instrumentation-your-gem.gemspec
spec.add_dependency 'opentelemetry-helpers-sql-processor'
```

Add the gem to your instrumentation's Gemfile:

```ruby
# Gemfile
group :test do
  gem 'opentelemetry-helpers-sql-processor', path: '../../helpers/sql-processor'
end
```

## Usage

The gem provides two main utilities through a unified API:

```ruby
require 'opentelemetry/helpers/sql_processor'
```

## SQL Obfuscation

Remove sensitive parameter values from SQL queries while preserving the query structure:

```ruby
# Basic usage
obfuscated = OpenTelemetry::Helpers::SqlProcessor.obfuscate_sql(
  "SELECT * FROM users WHERE email = 'user@example.com'",
  adapter: :postgres
)
# => "SELECT * FROM users WHERE email = ?"

# With custom limits
obfuscated = OpenTelemetry::Helpers::SqlProcessor.obfuscate_sql(
  long_sql_query,
  obfuscation_limit: 2000,
  adapter: :mysql
)
```

### Supported Database Adapters

- `:default` - Generic SQL support
- `:mysql` - MySQL-specific patterns
- `:postgres` - PostgreSQL-specific patterns
- `:sqlite` - SQLite-specific patterns
- `:oracle` - Oracle-specific patterns
- `:cassandra` - Cassandra CQL support

### Configuration Options

- `:obfuscation_limit` - Maximum length for obfuscation (default: 2000)
- `:adapter` - Database adapter type (default: `:default`)

## Query Summarization

Generate high-level summaries of SQL queries for metrics, logging, and cardinality reduction:

```ruby
# Create a thread-safe cache instance
cache = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new(size: 1000)

# Generate summaries
summary = OpenTelemetry::Helpers::SqlProcessor.generate_summary(
  "SELECT u.name, p.title FROM users u JOIN posts p ON u.id = p.user_id WHERE u.active = true",
  cache: cache
)
# => "SELECT users posts"

# More examples
summary = OpenTelemetry::Helpers::SqlProcessor.generate_summary(
  "INSERT INTO orders (user_id, product_id, quantity) VALUES (1, 2, 3)",
  cache: cache
)
# => "INSERT orders"

summary = OpenTelemetry::Helpers::SqlProcessor.generate_summary(
  "UPDATE user_profiles SET last_login = NOW() WHERE user_id = ?",
  cache: cache
)
# => "UPDATE user_profiles"
```

### Query Summary Features

- **Smart Pattern Recognition**: Handles complex SQL including JOINs, UNIONs, subqueries
- **Table Name Extraction**: Identifies all referenced tables and views
- **Operation Classification**: Recognizes DML, DDL, and procedure calls
- **Memory Efficient**: Reduces query strings by 80-90% on average
- **High Performance**: 278K+ operations/second for simple queries with optimizations

### Performance Characteristics

The query summarization engine is highly optimized:

| Query Type | Performance | Cache Hit Performance |
| ---------- | ----------- | -------------------- |
| Simple SELECT | ~278K ops/sec | ~3M ops/sec |
| Complex JOIN queries | ~5K ops/sec | ~1.7M ops/sec |
| UNION queries | ~193K ops/sec | ~2M ops/sec |
| DDL statements | ~148K ops/sec | ~2M ops/sec |

### Cache Configuration

```ruby
# Default cache (1000 entries, LRU eviction)
cache = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new

# Custom cache size
cache = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new(size: 500)

# In production, share cache instances across requests for optimal performance
SHARED_CACHE = OpenTelemetry::Helpers::SqlProcessor::QuerySummary::Cache.new(size: 5000)
```

## Architecture

### Query Summary Pipeline

1. **Fast Path Detection**: Common patterns are matched via optimized regex
2. **Tokenization**: SQL is parsed into structured tokens (keywords, identifiers, operators)
3. **State Machine Parsing**: Tokens are processed through parsing states to build summaries
4. **Summary Consolidation**: Multiple operations (e.g., UNION queries) are combined
5. **Caching**: Results are stored in thread-safe LRU cache for subsequent requests

### Modular Design

The gem uses a modular architecture with specialized components:

- `Tokenizer`: Converts SQL strings into structured tokens
- `Parser`: Processes tokens through parsing states with specialized handlers:
  - `TokenProcessor`: Main parsing logic and state management
  - `OperationHandler`: Handles SQL operations (SELECT, INSERT, UPDATE, etc.)
  - `DdlHandler`: Manages DDL operations and procedure patterns
  - `TableProcessor`: Extracts and processes table names and aliases
  - `SummaryConsolidator`: Combines multiple operations (UNION queries)
- `Cache`: Thread-safe LRU cache with configurable eviction

## Extending for New Database Adapters

### Adding Obfuscation Support

To add support for a new database adapter:

1. Update `DIALECT_COMPONENTS` in the obfuscator with your adapter's patterns
2. Update `CLEANUP_REGEX` with adapter-specific cleanup rules
3. Add a new constant: `<ADAPTER>_COMPONENTS_REGEX`

Reference the [New Relic SQL Obfuscation Helpers][new-relic-obfuscation-helpers] for existing patterns.

### Adding Query Summary Support

Query summarization automatically supports most SQL dialects, but you can extend it:

1. Add new keywords to the `KEYWORDS_ARRAY` in the tokenizer
2. Update parsing constants for adapter-specific operations
3. Add specialized handlers for unique SQL constructs

## Performance and Benchmarking

The gem includes comprehensive benchmarks in `benchmarks/query_summary_bench.rb`:

```bash
# Run performance benchmarks
ruby benchmarks/query_summary_bench.rb

# Run tracer benchmarks
ruby benchmarks/tracer_bench.rb
```

### Production Recommendations

1. **Use shared cache instances** across requests to maximize cache hit rates
2. **Size caches appropriately** - 1000-5000 entries handle most workloads
3. **Monitor cache hit rates** - should be >90% in production
4. **Profile your specific workload** using the included benchmarks

## Testing

The gem includes comprehensive tests with 99.6%+ code coverage:

```bash
# Run all tests
bundle exec rake test

# Run specific test suites
bundle exec ruby -Itest test/opentelemetry/helpers/sql_processor/query_summary/
```

## How can I get involved?

The `opentelemetry-helpers-sql-processor` gem source is [on github][repo-github], along with related gems including `opentelemetry-instrumentation-pg` and `opentelemetry-instrumentation-trilogy`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry Ruby special interest group (SIG). You can get involved by joining us on our [GitHub Discussions][discussions-url], [Slack Channel][slack-channel] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-helpers-sql-processor` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[new-relic-obfuscation-helpers]: https://github.com/newrelic/newrelic-ruby-agent/blob/96e7aca22c1c873c0f5fe704a2b3bb19652db68e/lib/new_relic/agent/database/obfuscation_helpers.rb
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby-contrib/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[slack-channel]: https://cloud-native.slack.com/archives/C01NWKKMKMY
[discussions-url]: https://github.com/open-telemetry/opentelemetry-ruby/discussions

# Semantic Convention Stability Migration Notes

This document captures the patterns and learnings from migrating the Trilogy instrumentation to support semantic convention stability, to help with migrating other database instrumentations.

## Architecture Pattern

Three client patches based on `OTEL_SEMCONV_STABILITY_OPT_IN` environment variable:
- `old/client.rb` - Original semantic conventions (default when env var is unset)
- `stable/client.rb` - New stable conventions (when env var is `database`)
- `dup/client.rb` - Both old and stable (when env var is `database/dup`)

## Attribute Mappings

| Old Attribute | Stable Attribute | Notes |
|--------------|------------------|-------|
| `db.system` | `db.system.name` | |
| `net.peer.name` | `server.address` | |
| `db.name` | `db.namespace` | |
| `db.statement` | `db.query.text` | |
| `db.user` | *(removed)* | Not in stable semconv |
| `db.instance.id` | *(removed)* | Not in stable semconv |
| `db.operation` | `db.operation.name` | Used for custom span naming |
| *(not in old)* | `server.port` | Always include when present (important for sampling) |
| *(not in old)* | `error.type` | Set to exception class name |
| *(not in old)* | `db.response.status_code` | Set to error code as string |

## Key Implementation Details

### server.port
- Always include when present (not just when non-default)
- Important for sampling decisions per the spec

### net.peer.port
- Don't add to dup mode if it wasn't in the original old implementation
- Only add new stable attributes to dup, don't backfill missing old attributes

### Error Attributes (stable only)
```ruby
def set_error_attributes(span, error)
  span.set_attribute('error.type', error.class.name)
  span.set_attribute('db.response.status_code', error.error_code.to_s) if error.respond_to?(:error_code) && error.error_code
end
```

Example values:
- `error.type`: `"Trilogy::ProtocolError"`
- `db.response.status_code`: `"1054"` (MySQL's "Unknown column" error)

## Test Structure

### Key Principle
Keep stable/dup tests **identical in structure** to old tests - only change the attribute names being asserted. This makes PR review much easier.

### Test Sections to Include
- `it 'has #name'` and `it 'has #version'`
- `describe '#compatible?'` with version checks
- `describe '#install'` with peer_service tests
- `describe 'tracing'` with:
  - `.attributes` tests
  - `with default options` tests
  - `when connecting` tests
  - `when pinging` tests
  - `when quering for the connected host` tests
  - `when quering using unix domain socket` tests (skipped)
  - `when queries fail` tests (including error.type and db.response.status_code for stable/dup)
  - `when db_statement is set to include/obfuscate/omit` tests
  - `when propagator is set to none/nil/vitess/tracecontext` tests
  - `when db_statement is configured via environment variable` tests
  - `when span_name is set as statement_type/db_name/db_operation_and_name` tests

### Attribute Name Differences in Tests
Use the correct attribute name for each mode:
- Old: `'db.operation'`
- Stable: `'db.operation.name'`
- Dup: `'db.operation'` (uses old name since it's user-provided)

## Files to Create/Modify

```
lib/opentelemetry/instrumentation/<gem>/
├── instrumentation.rb        # Add semconv detection logic
└── patches/
    ├── old/client.rb         # Original (may need to rename from client.rb)
    ├── stable/client.rb      # New stable semconv
    └── dup/client.rb         # Both old + stable

test/.../patches/
├── old/
│   ├── instrumentation_test.rb
│   └── client_attributes_test.rb
├── stable/
│   ├── instrumentation_test.rb
│   └── client_attributes_test.rb
└── dup/
    ├── instrumentation_test.rb
    └── client_attributes_test.rb

Appraisals                    # Add stable/dup variants for each gem version
.rubocop.yml                  # Exclude new files from Metrics/ModuleLength
```

### Appraisals Example
```ruby
appraise 'trilogy-2-old' do
  gem 'trilogy', '~> 2.0'
end

appraise 'trilogy-2-stable' do
  gem 'trilogy', '~> 2.0'
  ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database'
end

appraise 'trilogy-2-dup' do
  gem 'trilogy', '~> 2.0'
  ENV['OTEL_SEMCONV_STABILITY_OPT_IN'] = 'database/dup'
end
```

### .rubocop.yml Example
```yaml
Metrics/ModuleLength:
  Exclude:
    - "lib/opentelemetry/instrumentation/trilogy/patches/stable/client.rb"
    - "lib/opentelemetry/instrumentation/trilogy/patches/dup/client.rb"
```

## Testing with MySQL

### Using docker-compose (recommended)
```bash
# From repo root - already configured with mysql_native_password
cd /path/to/opentelemetry-ruby-contrib
docker-compose up -d mysql
```

### Standalone container
```bash
docker run -d --name mysql-test -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=mysql \
  mysql:8.0.31 mysqld --default-authentication-plugin=mysql_native_password
```

### Running tests
```bash
export TEST_MYSQL_HOST=127.0.0.1
export TEST_MYSQL_PORT=3307
export TEST_MYSQL_USER=root
export TEST_MYSQL_PASSWORD=root
export TEST_MYSQL_DB=mysql

# Run all tests
bundle exec appraisal rake test

# Run specific appraisal
bundle exec appraisal trilogy-2-stable rake test
```

## Common Issues

### Local MySQL Conflict
Check what's running on port 3306:
```bash
lsof -i :3306
```
If local MySQL is running, use a different port (3307) for the test container.

### caching_sha2_password Error
```
Trilogy::BaseConnectionError: trilogy_auth_recv: caching_sha2_password requires either TCP with TLS or a unix socket
```
Solution: Use `--default-authentication-plugin=mysql_native_password` when starting MySQL.

### Quote Style in .rubocop.yml
Use double quotes for CI compatibility:
```yaml
# Good
Exclude:
  - "lib/path/to/file.rb"

# Bad (may fail CI)
Exclude:
  - 'lib/path/to/file.rb'
```

## PR Description Template

```markdown
## Summary
- Adds support for stable database semantic conventions via `OTEL_SEMCONV_STABILITY_OPT_IN`
- Three modes: old (default), stable (`database`), dup (`database/dup`)

## Changes
- Added `patches/old/client.rb` - original semantic conventions
- Added `patches/stable/client.rb` - stable semantic conventions
- Added `patches/dup/client.rb` - emits both old and stable
- Updated instrumentation.rb to select patch based on env var
- Added comprehensive tests for each mode

## Attribute Changes (stable mode)
| Old | Stable |
|-----|--------|
| db.system | db.system.name |
| net.peer.name | server.address |
| db.name | db.namespace |
| db.statement | db.query.text |
| db.user | (removed) |
| (new) | server.port |
| (new) | error.type |
| (new) | db.response.status_code |

## Test plan
- [ ] All existing tests pass
- [ ] New stable tests pass
- [ ] New dup tests pass
- [ ] Manual testing with MySQL
```

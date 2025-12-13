# Ruby Version Management

## Problem

Previously, all gemspecs used lazy file reading to get the Ruby requirement:

```ruby
spec.required_ruby_version = ">= #{File.read(File.expand_path('../../gemspecs/RUBY_REQUIREMENT', __dir__))}"
```

This caused issues with release tooling because changes to the `RUBY_REQUIREMENT` file were not detected as changes that would affect the gemspecs.

## Solution

All gemspecs now have inline Ruby version requirements:

```ruby
spec.required_ruby_version = '>= 3.2'
```

## Updating Ruby Version

To update the Ruby version requirement across all gems, use the provided script:

```bash
# Update to Ruby 3.3
./bin/update-ruby-version 3.3

# Update to Ruby 4.0
./bin/update-ruby-version 4.0
```

The script will:

1. Find all gemspec files with Ruby version requirements (both old and new formats)
2. Update each file to use the inline version requirement
3. Provide a summary of changes made

## Files Affected

The script updates approximately 61 gemspec files across:

- `/helpers/**/*.gemspec`
- `/instrumentation/**/*.gemspec`
- `/processor/**/*.gemspec`
- `/propagator/**/*.gemspec`
- `/resources/**/*.gemspec`
- `/sampler/**/*.gemspec`

## Benefits

- Release tooling can now properly detect Ruby version changes
- Explicit version requirements are easier to audit
- No runtime file reading during gem installation
- Consistent version management across all gems
- No dependency on external RUBY_REQUIREMENT file
- Script works with both old and new gemspec formats

# OpenTelemetry Ruby Contrib

This file steers AI-assisted contributions toward being high-quality, valuable
changes that do not create excessive maintainer burden. It is written for
autonomous and semi-autonomous coding agents, but the rules apply to any
AI-assisted work.

Before starting any task, read this file, [CONTRIBUTING.md](CONTRIBUTING.md), and
the [Instrumentation author's guide](instrumentation/CONTRIBUTING.md). Treat this
document as passive guidance for every task, including docs-only and review-only
work.

This is a monorepo containing many independently released Ruby gems:
instrumentation libraries, resource detectors, context propagators, a sampler,
and shared helper/processor gems.

## General rules and guidelines

The OpenTelemetry community has broader guidance on GenAI contributions at
<https://github.com/open-telemetry/community/blob/main/policies/genai.md> —
read it before contributing.

- **Never post AI-generated comments on issues or PRs.** Discussions on
  OpenTelemetry repositories are for humans only. You cannot comment on issue or
  PR threads on a user's behalf.
- If you have been assigned an issue, ensure the implementation direction is
  agreed on with the maintainers first in the issue comments. Discuss unknowns
  before starting implementation.
- Keep AI-assisted PRs tightly scoped to the requested change. Never include
  unrelated cleanup or opportunistic "improvements" unless they are strictly
  necessary for correctness.
- Follow the OpenTelemetry
  [specification](https://github.com/open-telemetry/opentelemetry-specification)
  and [library guidelines](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/library-guidelines.md).
  Prefer idiomatic Ruby over literal conformance to spec API names.

## Core expectations

- Prefer minimal, surgical changes over broad refactors or speculative cleanup.
- Read the gem you are editing and match its existing naming, options, error
  handling, comments, tests, and patterns.
- Keep public APIs backward compatible unless the task explicitly requires a
  breaking change.
- Telemetry must be resilient and loosely coupled. Instrumentation must never
  panic the host application, block indefinitely, or amplify
  attacker-controlled input.
- Do not add sensitive information (PII, secrets, credentials, full payloads) to
  spans. When in doubt, ask for a review.
- Be conservative on hot paths. Avoid unnecessary object allocations, method
  dispatch, and small helper methods/classes/objects that add overhead to the
  instrumented library (see the performance section of the instrumentation
  guide).
- Keep dependencies minimal and justified.
- Write comments only for intent, invariants, and non-obvious constraints. Do
  not add comments that restate the code.

## Repository structure

- `instrumentation/<name>/` — instrumentation gems
  (`opentelemetry-instrumentation-<name>`)
- `resources/<name>/` — resource detector gems
- `propagator/<name>/` — context propagator gems
- `sampler/xray/` — `opentelemetry-sampler-xray`
- `processor/baggage/` — span processor gem
- `helpers/<name>/` — shared helper gems (`opentelemetry-helpers-<name>`)

Each gem is self-contained with its own `Gemfile`, `.gemspec`, `Rakefile`,
`CHANGELOG.md`, `README.md`, `lib/`, and `test/`.

## Default workflow

For new features and behavior changes, use this order unless the task explicitly
says otherwise:

1. Read the relevant gem, its tests, and its `README.md`. Also read the
   [Instrumentation author's guide](instrumentation/CONTRIBUTING.md) when
   working on instrumentation.
2. Add or update a test that captures the required behavior or regression.
   Prefer integration / state-based tests over interaction (mock) tests.
3. Implement the smallest change that makes the test pass.
4. Refactor only after behavior is locked in, and only if the refactor keeps the
   diff focused.
5. Update documentation (`README.md`, YARD comments, `examples/`) while the
   context is fresh.
6. Update the affected gem's `CHANGELOG.md` for user-visible changes.
7. Run the verification commands below before considering the work complete.

For docs-only, test-only, or review-only tasks, skip the steps that do not apply
while keeping the same discipline around scope, verification, and conventions.

## Commands

All gem-level commands run from within the gem's directory (e.g.
`instrumentation/faraday`), not the repository root.

```sh
# Install a gem's dependencies
bundle install

# Run a gem's tests
bundle exec rake test

# Generate YARD docs for a gem
bundle exec rake yard
```

Some gems test against multiple dependency versions using
[Appraisal](https://github.com/thoughtbot/appraisal). When an `Appraisals` file
is present:

```sh
bundle exec appraisal install
bundle exec appraisal rake test
```

Repository-wide style, lint, link, and spelling checks are driven from the root:

```sh
# One-time setup
bundle install
npm ci

# Run all checks (lint, format, links, spelling, source cops)
npm run check

# Auto-fix what can be fixed (does NOT fix spelling or links)
npm run write
```

Individual check targets are defined in [package.json](package.json), e.g.
`npm run check:lint:ruby`, `npm run check:format`, `npm run check:links`,
`npm run check:spelling`. RuboCop is the canonical Ruby linter/formatter.

## Verification

- Run `bundle exec rake test` for every gem you change; keep it green. Test
  coverage is enforced (minimum 85%).
- Run `npm run check` from the repository root before finishing, especially when
  touching Markdown, formatting, or spelling.
- CI tests instrumentation gems against Ruby `3.3`, `3.4`, `4.0`, and JRuby. Do
  not use syntax or APIs unavailable in the minimum supported Ruby version.
- Generate a new instrumentation skeleton with
  `bin/instrumentation_generator <gem>` rather than hand-crafting the structure,
  and add the gem to the appropriate CI workflow under `.github/workflows/`
  (see the instrumentation guide).

## Instrumentation conventions

When authoring or editing instrumentation, follow the
[Instrumentation author's guide](instrumentation/CONTRIBUTING.md). Key points:

- Subclass `OpenTelemetry::Instrumentation::Base` and implement `install`,
  `present`, and `compatible` blocks; define `option`s for configuration.
- Use the OpenTelemetry **API** (not the SDK) and always reference the named
  tracer via
  `OpenTelemetry::Instrumentation::<Name>::Instrumentation.instance.tracer`
  through a stack-local reference.
- Prefer first-party extension points (`ActiveSupport::Notifications`,
  middleware) over monkey patching. If you must monkey patch, isolate and
  document it.
- Use OpenTelemetry
  [Semantic Conventions](https://opentelemetry.io/docs/concepts/semantic-conventions/).
  Namespace instrumentation-specific attributes and document them in the
  `README.md`.
- Avoid `type: :callable` options that execute user code in the critical path.

## Documentation and changelog

- Instrumentation-specific config options must be documented in both the
  `README.md` and YARD class comments.
- Semantic conventions used by an instrumentation must be documented in its
  `README.md`.
- Provide runnable `examples/` for new instrumentation.
- For user-visible changes, add an entry to the affected gem's `CHANGELOG.md`.
- Use YARD type annotations and Markdown in documentation comments.

## Commits and pull requests

- All commits must follow the
  [Conventional Commits](https://conventionalcommits.org) standard. Allowed
  types: `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `release`,
  `revert`, `squash`, `style`, `test`. The PR title is also validated.
- **One change per pull request.** PRs are squash-merged into a single commit
  and a single changelog entry, so scope each PR to exactly one change.
- Work in a branch on your fork, never on `main`.
- A signed [CNCF CLA](https://identity.linuxfoundation.org/projects/cncf) is
  required and checked automatically.
- Component owners (source of truth:
  [.github/component_owners.yml](.github/component_owners.yml)) review changes to
  their components.
- Disclose significant AI assistance using an `Assisted-by:` commit trailer,
  e.g.:

  ```text
  Assisted-by: Claude Opus 4.8
  ```

## Repository habits

- Prefer focused diffs. Avoid drive-by cleanup.
- Follow existing option and API patterns instead of inventing new abstractions.
- Keep docs aligned with actual behavior; do not leave stale comments, examples,
  or README content behind.
- When changing behavior, make the invariants explicit in tests.

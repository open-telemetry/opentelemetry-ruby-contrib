# Release History: opentelemetry-instrumentation-grape

## 1.0.0 (2023-12-22)


### Features

* add Grape instrumentation ([#394](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/394)) ([98baa88](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/98baa88ed0979702f56b804b34f397debe9bbaad))
* Use Rack Middleware Helper ([#428](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/428)) ([78a137e](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/78a137e6e95e4f4358e9a0f46d5e3e929e9f35be))


### Bug Fixes

* Base config options ([#499](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/499)) ([7304e86](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/7304e86e9a3beba5c20f790b256bbb54469411ca))
* Fix opentelemetry-api version constraint in grape gemspec ([#604](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/604)) ([76c3eac](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/76c3eacf1e770f97ffd557ed694db929456a1db9))
* Grape Instrumentation handle status code symbol ([#448](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/448)) ([cf8982a](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/cf8982a595d06400dde814aad9818bf2a8218428))
* regex non-match with obfuscation limit (issue [#486](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/486)) ([#488](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/488)) ([6a9c330](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/6a9c33088c6c9f39b2bc30247a3ed825553c07d4))
* Remove dependency on ActiveSupport core extensions from Grape instrumentation ([#706](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/706)) ([c5f5c58](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/c5f5c5886295e2fdf06e162178f6a1af91630c70))
* remove redundant require statement for 'rack' from grape instrumentation ([#450](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/450)) ([caf47c1](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/caf47c1c92b465f734222347f0813ac4f0bb06bb))
* Set grape.formatter.type to 'custom' for non-Grape formatters ([#444](https://github.com/open-telemetry/opentelemetry-ruby-contrib/issues/444)) ([673ab6e](https://github.com/open-telemetry/opentelemetry-ruby-contrib/commit/673ab6e4af1f62de556a99be436a3e2f0179d094))

### v0.1.6 / 2023-11-23

* CHANGED: Applied Rubocop Performance Recommendations [#727](https://github.com/open-telemetry/opentelemetry-ruby-contrib/pull/727)

### v0.1.5 / 2023-10-31

* FIXED: Remove dependency on ActiveSupport core extensions from Grape instrumentation

### v0.1.4 / 2023-08-02

* FIXED: Fix opentelemetry-api version constraint in grape gemspec

### v0.1.3 / 2023-06-05

* FIXED: Base config options 

### v0.1.2 / 2023-05-02

* FIXED: Grape Instrumentation handle status code symbol

### v0.1.1 / 2023-04-26

* FIXED: Set grape.formatter.type to 'custom' for non-Grape formatters

### v0.1.0 / 2023-04-17

* Initial release.

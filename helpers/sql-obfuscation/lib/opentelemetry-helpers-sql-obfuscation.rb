# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'opentelemetry/helpers'

OpenTelemetry.logger.warn <<~WARNING
  [DEPRECATION] The 'opentelemetry-helpers-sql-obfuscation' is deprecated and has been replaced by 'opentelemetry-helpers-sql-processor'.
  Please update your Gemfile to use 'opentelemetry-helpers-sql-processor' instead.
WARNING

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'opentelemetry/helpers'

OpenTelemetry.logger.warn <<~WARNING
  [DEPRECATION] The 'opentelemetry-helpers-sql-obfuscation' gem has been renamed to 'opentelemetry-helpers-sql-processor'. No action is needed unless you use this gem directly.
WARNING

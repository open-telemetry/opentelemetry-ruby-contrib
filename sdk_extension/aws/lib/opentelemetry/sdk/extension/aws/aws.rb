# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-api'
require 'opentelemetry/sdk/extension/aws/version'
require 'opentelemetry/sdk/extension/aws/trace/xray_id_generator'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry SDK libraries
  module SDK
    # Namespace for OpenTelemetry SDK Extension libraries
    module Extension
      # Namespace for OpenTelemetry AWS SDK Extension
      module Aws
      end
    end
  end
end

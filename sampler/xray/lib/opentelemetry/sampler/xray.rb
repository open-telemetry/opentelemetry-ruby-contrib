# frozen_string_literal: true

# Copyright OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.

module OpenTelemetry
  module Sampler
    # Namespace for OpenTelemetry XRay Sampler
    module XRay
    end
  end
end

require_relative 'xray/version'
require_relative 'xray/aws_xray_remote_sampler'

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Helpers
    # Provides semantic convention helpers for OpenTelemetry spans.
    #
    # This module contains utilities that help instrumentation libraries create
    # consistent span names and attributes according to OpenTelemetry semantic
    # conventions. It's designed to be used by instrumentation authors, not
    # end users directly.
    #
    # ## Available Helpers
    #
    # ### HTTP
    # The {OpenTelemetry::Helpers::Semconv::HTTP} module provides utilities for
    # naming HTTP spans consistently across different instrumentation libraries.
    module Semconv
    end
  end
end

require_relative 'semconv/http'
require_relative 'semconv/version'

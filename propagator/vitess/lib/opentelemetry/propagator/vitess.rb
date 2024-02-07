# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'json'
require 'base64'
require 'opentelemetry-api'
require 'opentelemetry/propagator/jaeger'
require 'opentelemetry/propagator/vitess/version'
require 'opentelemetry/propagator/vitess/sql_query_propagator'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # Namespace for OpenTelemetry propagator extension libraries
  module Propagator
    # Namespace for OpenTelemetry Vitess propagation
    module Vitess
      extend self

      SQL_QUERY_PROPAGATOR = SqlQueryPropagator.new

      private_constant :SQL_QUERY_PROPAGATOR

      # Returns a sql query propagator that propagates context using the
      # Vitess format.
      def sql_query_propagator
        SQL_QUERY_PROPAGATOR
      end
    end
  end
end

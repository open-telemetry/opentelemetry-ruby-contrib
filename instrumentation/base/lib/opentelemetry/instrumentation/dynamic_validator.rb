# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # Can wrap a static validation in this class to allow users to
    # alternatively invoke a callable.
    class DynamicValidator
      def initialize(static_validation)
        raise ArgumentError, 'static_validation cannot be dynamic' if static_validation.is_a?(self.class)

        @static_validation = static_validation
      end

      attr_reader :static_validation
    end
  end
end

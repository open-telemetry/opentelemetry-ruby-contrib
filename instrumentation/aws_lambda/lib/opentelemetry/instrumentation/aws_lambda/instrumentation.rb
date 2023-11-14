# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsLambda
      # Instrumentation class that detects and installs the AwsLambda instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
        end

        present do
          # maybe check if ORIG_HANDLER or _HANLDER exist
          true
        end

        compatible do
          true
        end

        private

        def require_dependencies
          require_relative 'handler'
        end
      end
    end
  end
end

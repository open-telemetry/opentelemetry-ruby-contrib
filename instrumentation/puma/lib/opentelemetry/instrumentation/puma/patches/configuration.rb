# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Puma
      module Patches
        # The Configuration module adds the instrumentation plugin
        module Configuration
          def initialize(...)
            super
            @user_dsl.plugin('opentelemetry')
          end
        end
      end
    end
  end
end

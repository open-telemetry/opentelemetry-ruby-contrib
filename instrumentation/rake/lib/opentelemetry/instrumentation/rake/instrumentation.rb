# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Rake
      # The Instrumentation class contains logic to detect and install the Rake instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_rake
          shutdown_at_exit
        end

        present do
          defined?(::Rake::Task)
        end

        private

        def require_dependencies
          require_relative './patches/task'
        end

        def patch_rake
          ::Rake::Task.prepend(Patches::Task)
        end

        def shutdown_at_exit
          return unless defined?(::Rake) && !::Rake.application.top_level_tasks.empty?

          at_exit { OpenTelemetry.tracer_provider.shutdown }
        end
      end
    end
  end
end

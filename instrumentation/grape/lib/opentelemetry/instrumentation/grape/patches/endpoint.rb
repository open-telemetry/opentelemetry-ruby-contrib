# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grape
      module Patches
        # Module to prepend to Grape::Endpoint for instrumentation
        module Endpoint
          def self.included(base)
            base.singleton_class.prepend(ClassMethods)
            base.prepend(InstanceMethods)
          end

          module ClassMethods
            def generate_api_method(*params, &block)
              method_api = super

              proc do |*args|
                ::ActiveSupport::Notifications.instrument('endpoint_render.grape.start_render')
                method_api.call(*args)
              end
            end
          end

          module InstanceMethods
            def run(*args)
              ::ActiveSupport::Notifications.instrument('endpoint_run.grape.start_process', endpoint: self, env: env)
              super
            end
          end
        end
      end
    end
  end
end

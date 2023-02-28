# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Grape
      # This class subscribes to the generated ActiveSupport notifications and generates spans based on them.
      class Handler
        SUBSCRIPTIONS = {
          'endpoint_run.grape' => endpoint_run,
          'endpoint_render.grape' => endpoint_render,
          'endpoint_run_filters.grape' => endpoint_run_filters,
          'endpoint_run_validators.grape' => endpoint_run_validators,
          'format_response.grape' => format_response
        }.freeze

        class << self
          def subscribe
            SUBSCRIPTIONS.each do |event, _subscriber|
              ::ActiveSupport::Notifications.subscribe(event) do |*args|
                subscriber(*args)
              end
            end
          end

          private

          def endpoint_run(name, start, finish, id, payload); end

          def endpoint_render(name, start, finish, id, payload); end

          def endpoint_run_filters(name, start, finish, id, payload); end

          def endpoint_run_validators(name, start, finish, id, payload); end

          def format_response(name, start, finish, id, payload); end
        end
      end
    end
  end
end

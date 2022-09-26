# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      module Patches
        module ActionController
          # Module to prepend to ActionController::Metal for instrumentation
          module Metal
            def dispatch(name, request, response)
              rack_span = OpenTelemetry::Instrumentation::Rack.current_span
              if rack_span.recording?
                route = rails_route(request)
                unless request.env['action_dispatch.exception']
                  rack_span.name = case instrumentation_config[:span_naming]
                                   when :controller_action then "#{self.class.name}##{name}"
                                   else "#{request.method} #{route}"
                                   end
                end

                rack_span.set_attribute('http.route', route) if instrumentation_config[:enable_recognize_route]

                rack_span.set_attribute('http.target', request.filtered_path) if request.filtered_path != request.fullpath
              end

              super(name, request, response)
            end

            private

            def rails_route(request)
              ::Rails.application.routes.router.recognize(request) do |route, _params|
                return route.path.spec.to_s
                # Rails will match on the first route - see https://guides.rubyonrails.org/routing.html#crud-verbs-and-actions
              end
            end

            def instrumentation_config
              ActionPack::Instrumentation.instance.config
            end
          end
        end
      end
    end
  end
end

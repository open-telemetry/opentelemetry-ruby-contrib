# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionPack
      module Handlers
        # Action controller handler to handle the notification from ActiveSupport
        class ActionController
          # @param config [Hash] of instrumentation options
          def initialize(config)
            @config = config
          end

          # Invoked by ActiveSupport::Notifications at the start of the instrumentation block
          #
          # @param _name [String] of the Event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] containing job run information
          # @return [Hash] the payload passed as a method argument
          def start(_name, _id, payload)
            
            rack_span = OpenTelemetry::Instrumentation::Rack.current_span

            rack_span.name = "#{payload[:controller]}##{payload[:action]}" unless payload[:request]&.env['action_dispatch.exception']

            attributes_to_append = {
              OpenTelemetry::SemanticConventions::Trace::CODE_NAMESPACE => String(payload[:controller]),
              OpenTelemetry::SemanticConventions::Trace::CODE_FUNCTION => String(payload[:action])
            }

            attributes_to_append[OpenTelemetry::SemanticConventions::Trace::HTTP_TARGET] = payload[:request]&.filtered_path if payload[:request]&.filtered_path != payload[:request]&.fullpath
            rack_span.add_attributes(attributes_to_append)
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end

          # Invoked by ActiveSupport::Notifications at the end of the instrumentation block
          #
          # @param _name [String] of the Event (unused)
          # @param _id [String] of the event (unused)
          # @param payload [Hash] containing job run information
          # @return [Hash] the payload passed as a method argument
          def finish(_name, _id, payload)

            # payload in finish: {:controller=>"UsersController", :action=>"new", :request=>#<ActionDispatch::Request GET "http://0.0.0.0:8002/users/new" for 127.0.0.1>, 
            # :params=>{"controller"=>"users", "action"=>"new"}, :headers=>#<ActionDispatch::Http::Headers:0x0000ffff876add80 @req=#<ActionDispatch::Request GET "http://0.0.0.0:8002/users/new" for 127.0.0.1>>, 
            # :format=>"*/*", :method=>"GET", :path=>"/users/new", :view_runtime=>nil, :db_runtime=>0.23200000578071922, 
            # :exception=>["NoMethodError", "undefined method `asdfsf' for #<User id: nil, name: nil, email: nil, created_at: nil, updated_at: nil, password_digest: nil, remember_digest: nil, admin: false, activation_digest: nil, activated: false, activated_at: nil, reset_digest: nil, reset_sent_at: nil>"], 
            # :exception_object=>#<NoMethodError: undefined method `asdfsf' for #<User id: nil, name: nil, email: nil, created_at: nil, updated_at: nil, password_digest: nil, remember_digest: nil, admin: false, activation_digest: nil, activated: false, activated_at: nil, reset_digest: nil, reset_sent_at: nil>>}
            # error will appear here

            rack_span = OpenTelemetry::Instrumentation::Rack.current_span
            rack_span.record_exception(payload[:exception_object]) if payload[:exception_object]
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e)
          end
        end
      end
    end
  end
end
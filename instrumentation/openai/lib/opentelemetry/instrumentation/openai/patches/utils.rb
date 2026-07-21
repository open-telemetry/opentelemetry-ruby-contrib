# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module OpenAI
      module Patches
        # Utils
        module Utils
          # Retrieves a property value from a Hash or object by name.
          def get_property_value(obj, property_name)
            if obj.is_a?(Hash)
              obj[property_name] || obj[property_name.to_sym]
            else
              obj.respond_to?(property_name) ? obj.public_send(property_name) : nil
            end
          end

          # Extracts and normalizes tool call data from a message or choice object.
          def extract_tool_calls(item, capture_content)
            tool_calls = get_property_value(item, :tool_calls)
            return nil unless tool_calls

            calls = []
            tool_calls.each do |tool_call|
              tool_call_dict = {}

              call_id = get_property_value(tool_call, :id)
              tool_call_dict[:id] = call_id if call_id

              tool_type = get_property_value(tool_call, :type)
              tool_call_dict[:type] = tool_type.to_s if tool_type

              func = get_property_value(tool_call, :function)
              if func
                tool_call_dict[:function] = {}

                name = get_property_value(func, :name)
                tool_call_dict[:function][:name] = name if name

                arguments = get_property_value(func, :arguments)
                if capture_content && arguments
                  arguments = arguments.to_s.delete("\n") if arguments.is_a?(String)
                  tool_call_dict[:function][:arguments] = arguments
                end
              end

              calls << tool_call_dict
            end
            calls
          end

          # Converts a request message into a structured gen_ai log event hash.
          def message_to_log_event(message, capture_content: true)
            role = get_property_value(message, :role)&.to_s
            content = get_property_value(message, :content)

            body = {}
            body[:content] = content.to_s if capture_content && content

            if role == 'assistant'
              tool_calls = extract_tool_calls(message, capture_content)
              body = { tool_calls: tool_calls } if tool_calls
            elsif role == 'tool'
              tool_call_id = get_property_value(message, :tool_call_id)
              body[:id] = tool_call_id if tool_call_id
            end

            {
              event_name: "gen_ai.#{role}.message",
              attributes: {
                'gen_ai.provider.name' => 'openai'
              },
              body: body.empty? ? nil : body
            }
          end

          # Converts a response choice into a structured gen_ai log event hash.
          def choice_to_log_event(choice, capture_content: true)
            index = get_property_value(choice, :index) || 0
            finish_reason = get_property_value(choice, :finish_reason)&.to_s || 'error'

            body = {
              index: index,
              finish_reason: finish_reason
            }

            message_obj = get_property_value(choice, :message)
            if message_obj
              message = {}
              role = get_property_value(message_obj, :role)
              message[:role] = role.to_s if role

              tool_calls = extract_tool_calls(message_obj, capture_content)
              message[:tool_calls] = tool_calls if tool_calls

              content = get_property_value(message_obj, :content)
              message[:content] = content.to_s if capture_content && content

              body[:message] = message
            end

            {
              event_name: 'gen_ai.choice',
              attributes: {
                'gen_ai.provider.name' => 'openai'
              },
              body: body
            }
          end

          # Emits a structured log record through the OpenTelemetry Logs API.
          def log_structured_event(event)
            logger = OpenTelemetry.logger_provider.logger(
              name: OpenTelemetry::Instrumentation::OpenAI::NAME,
              version: OpenTelemetry::Instrumentation::OpenAI::VERSION
            )

            logger.on_emit(
              timestamp: Time.now,
              severity_text: 'INFO',
              severity_number: OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_INFO,
              event_name: event[:event_name],
              body: event[:body],
              attributes: event[:attributes],
              context: OpenTelemetry::Context.current
            )
          end
        end
      end
    end
  end
end

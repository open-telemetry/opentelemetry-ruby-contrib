# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'json'

require_relative '../../../../../lib/opentelemetry/instrumentation/openai/patches/utils'

describe OpenTelemetry::Instrumentation::OpenAI::Patches::Utils do
  let(:utils_class) do
    Class.new do
      include OpenTelemetry::Instrumentation::OpenAI::Patches::Utils
    end.new
  end

  describe '#get_property_value' do
    it 'retrieves value from hash with string key' do
      obj = { 'name' => 'test' }
      _(utils_class.get_property_value(obj, 'name')).must_equal 'test'
    end

    it 'retrieves value from hash with symbol key' do
      obj = { name: 'test' }
      _(utils_class.get_property_value(obj, 'name')).must_equal 'test'
    end

    it 'retrieves value from object with method' do
      obj = Struct.new(:name).new('test')
      _(utils_class.get_property_value(obj, :name)).must_equal 'test'
    end

    it 'returns nil for non-existent property in hash' do
      obj = { name: 'test' }
      _(utils_class.get_property_value(obj, 'missing')).must_be_nil
    end

    it 'returns nil for non-existent method in object' do
      obj = Struct.new(:name).new('test')
      _(utils_class.get_property_value(obj, :missing)).must_be_nil
    end
  end

  describe '#extract_tool_calls' do
    it 'returns nil when tool_calls is not present' do
      item = { role: 'assistant', content: 'Hello' }
      _(utils_class.extract_tool_calls(item, true)).must_be_nil
    end

    it 'extracts tool call with id and type' do
      item = {
        tool_calls: [
          {
            id: 'call_123',
            type: 'function',
            function: {
              name: 'get_weather',
              arguments: '{"location":"NYC"}'
            }
          }
        ]
      }

      result = utils_class.extract_tool_calls(item, true)
      _(result).wont_be_nil
      _(result.length).must_equal 1
      _(result[0][:id]).must_equal 'call_123'
      _(result[0][:type]).must_equal 'function'
      _(result[0][:function][:name]).must_equal 'get_weather'
      _(result[0][:function][:arguments]).must_equal '{"location":"NYC"}'
    end

    it 'strips newlines from arguments when capture_content is true' do
      item = {
        tool_calls: [
          {
            id: 'call_123',
            type: 'function',
            function: {
              name: 'get_weather',
              arguments: "{\n  \"location\": \"NYC\"\n}"
            }
          }
        ]
      }

      result = utils_class.extract_tool_calls(item, true)
      _(result[0][:function][:arguments]).must_equal '{  "location": "NYC"}'
    end

    it 'omits arguments when capture_content is false' do
      item = {
        tool_calls: [
          {
            id: 'call_123',
            type: 'function',
            function: {
              name: 'get_weather',
              arguments: '{"location":"NYC"}'
            }
          }
        ]
      }

      result = utils_class.extract_tool_calls(item, false)
      _(result[0][:function][:arguments]).must_be_nil
    end

    it 'handles multiple tool calls' do
      item = {
        tool_calls: [
          {
            id: 'call_123',
            type: 'function',
            function: { name: 'get_weather' }
          },
          {
            id: 'call_456',
            type: 'function',
            function: { name: 'get_time' }
          }
        ]
      }

      result = utils_class.extract_tool_calls(item, true)
      _(result.length).must_equal 2
      _(result[0][:id]).must_equal 'call_123'
      _(result[1][:id]).must_equal 'call_456'
    end

    it 'handles tool_calls as objects with respond_to' do
      function_obj = Struct.new(:name, :arguments).new('get_weather', '{"location":"NYC"}')
      tool_call_obj = Struct.new(:id, :type, :function).new('call_123', :function, function_obj)
      item = Struct.new(:tool_calls).new([tool_call_obj])

      result = utils_class.extract_tool_calls(item, true)
      _(result).wont_be_nil
      _(result[0][:id]).must_equal 'call_123'
      _(result[0][:function][:name]).must_equal 'get_weather'
    end
  end

  describe '#message_to_log_event' do
    it 'creates log event for user message with content' do
      message = { role: 'user', content: 'Hello, how are you?' }
      event = utils_class.message_to_log_event(message, capture_content: true)

      _(event[:event_name]).must_equal 'gen_ai.user.message'
      _(event[:attributes]['gen_ai.provider.name']).must_equal 'openai'
      _(event[:body][:content]).must_equal 'Hello, how are you?'
    end

    it 'creates log event for system message' do
      message = { role: 'system', content: 'You are a helpful assistant.' }
      event = utils_class.message_to_log_event(message, capture_content: true)

      _(event[:event_name]).must_equal 'gen_ai.system.message'
      _(event[:body][:content]).must_equal 'You are a helpful assistant.'
    end

    it 'creates log event for assistant message with tool calls' do
      message = {
        role: 'assistant',
        tool_calls: [
          {
            id: 'call_123',
            type: 'function',
            function: {
              name: 'get_weather',
              arguments: '{"location":"NYC"}'
            }
          }
        ]
      }

      event = utils_class.message_to_log_event(message, capture_content: true)
      _(event[:event_name]).must_equal 'gen_ai.assistant.message'
      _(event[:body][:tool_calls]).wont_be_nil
      _(event[:body][:tool_calls][0][:id]).must_equal 'call_123'
    end

    it 'creates log event for tool message' do
      message = { role: 'tool', tool_call_id: 'call_123', content: 'Weather is sunny' }
      event = utils_class.message_to_log_event(message, capture_content: true)

      _(event[:event_name]).must_equal 'gen_ai.tool.message'
      _(event[:body][:id]).must_equal 'call_123'
      _(event[:body][:content]).must_equal 'Weather is sunny'
    end

    it 'omits content when capture_content is false' do
      message = { role: 'user', content: 'Hello' }
      event = utils_class.message_to_log_event(message, capture_content: false)

      _(event[:body]).must_be_nil
    end

    it 'handles role as symbol' do
      message = { role: :assistant, content: 'Hello' }
      event = utils_class.message_to_log_event(message, capture_content: true)

      _(event[:event_name]).must_equal 'gen_ai.assistant.message'
    end
  end

  describe '#choice_to_log_event' do
    it 'creates log event for choice with message content' do
      choice = {
        index: 0,
        finish_reason: 'stop',
        message: {
          role: 'assistant',
          content: 'Hello, how can I help you?'
        }
      }

      event = utils_class.choice_to_log_event(choice, capture_content: true)
      _(event[:event_name]).must_equal 'gen_ai.choice'
      _(event[:attributes]['gen_ai.provider.name']).must_equal 'openai'
      _(event[:body][:index]).must_equal 0
      _(event[:body][:finish_reason]).must_equal 'stop'
      _(event[:body][:message][:role]).must_equal 'assistant'
      _(event[:body][:message][:content]).must_equal 'Hello, how can I help you?'
    end

    it 'creates log event for choice with tool calls' do
      choice = {
        index: 0,
        finish_reason: 'tool_calls',
        message: {
          role: 'assistant',
          tool_calls: [
            {
              id: 'call_123',
              type: 'function',
              function: {
                name: 'get_weather',
                arguments: '{"location":"NYC"}'
              }
            }
          ]
        }
      }

      event = utils_class.choice_to_log_event(choice, capture_content: true)
      _(event[:body][:finish_reason]).must_equal 'tool_calls'
      _(event[:body][:message][:tool_calls]).wont_be_nil
      _(event[:body][:message][:tool_calls][0][:id]).must_equal 'call_123'
    end

    it 'defaults finish_reason to error when missing' do
      choice = {
        index: 0,
        message: { role: 'assistant', content: 'Hello' }
      }

      event = utils_class.choice_to_log_event(choice, capture_content: true)
      _(event[:body][:finish_reason]).must_equal 'error'
    end

    it 'defaults index to 0 when missing' do
      choice = {
        finish_reason: 'stop',
        message: { role: 'assistant', content: 'Hello' }
      }

      event = utils_class.choice_to_log_event(choice, capture_content: true)
      _(event[:body][:index]).must_equal 0
    end

    it 'omits content when capture_content is false' do
      choice = {
        index: 0,
        finish_reason: 'stop',
        message: {
          role: 'assistant',
          content: 'Hello'
        }
      }

      event = utils_class.choice_to_log_event(choice, capture_content: false)
      _(event[:event_name]).must_equal 'gen_ai.choice'
      _(event[:body][:index]).must_equal 0
      _(event[:body][:finish_reason]).must_equal 'stop'
      _(event[:body][:message][:role]).must_equal 'assistant'
      assert_equal(event[:attributes], { 'gen_ai.provider.name' => 'openai' })
      _(event[:body][:message][:content]).must_be_nil
    end

    it 'handles choice as object with respond_to methods' do
      message_obj = Struct.new(:role, :content).new('assistant', 'Hello')
      choice_obj = Struct.new(:index, :finish_reason, :message).new(0, 'stop', message_obj)

      event = utils_class.choice_to_log_event(choice_obj, capture_content: true)
      _(event[:body][:index]).must_equal 0
      _(event[:body][:finish_reason]).must_equal 'stop'
      _(event[:body][:message][:content]).must_equal 'Hello'
    end
  end

  describe '#log_structured_event' do
    it 'logs event as JSON to OpenTelemetry logger' do
      event = {
        event_name: 'gen_ai.user.message',
        attributes: { 'gen_ai.provider.name' => 'openai' },
        body: { content: 'Hello' }
      }

      # Capture logger output
      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output)

      utils_class.log_structured_event(event)

      OpenTelemetry.logger = original_logger

      logged_message = logger_output.string
      _(logged_message).must_include 'gen_ai.user.message'
      _(logged_message).must_include 'openai'
      _(logged_message).must_include 'Hello'
    end

    it 'handles events with nil body' do
      event = {
        event_name: 'gen_ai.user.message',
        attributes: { 'gen_ai.provider.name' => 'openai' },
        body: nil
      }

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output)

      utils_class.log_structured_event(event)

      OpenTelemetry.logger = original_logger

      logged_message = logger_output.string
      _(logged_message).must_include 'gen_ai.user.message'
      _(logged_message).wont_include 'body'
    end
  end
end

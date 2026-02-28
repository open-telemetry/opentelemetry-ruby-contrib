# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/openai'
require_relative '../../../../../lib/opentelemetry/instrumentation/openai/patches/stream_wrapper'

describe OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper do
  let(:instrumentation) { OpenTelemetry::Instrumentation::OpenAI::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:tracer) { instrumentation.tracer }

  before do
    exporter.reset
    instrumentation.install(capture_content: true)
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'streaming chat completion' do
    # NOTE: StreamWrapper wraps OpenAI::Internal::Stream[ChatCompletionChunk] which yields chunks directly.
    # This is different from client.chat.completions.stream() which yields events with .type and .chunk.
    # The instrumentation patches client.request() which returns the raw stream before event wrapping.

    it 'wraps stream and collects response data' do
      span = tracer.start_root_span('test_span', kind: :client)

      # Mock streaming chunks that simulate OpenAI::Models::Chat::ChatCompletionChunk structure
      # These are yielded directly by OpenAI::Internal::Stream when iterating
      chunks = [
        # First chunk with role
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content, :role).new('', :assistant),
              nil
            )
          ]
        ),
        # Content chunks
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('1'),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(' '),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('2'),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(' '),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('3'),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(' '),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('4'),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(' '),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('5'),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new("\n"),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('Done'),
              nil
            )
          ]
        ),
        # Final chunk with finish reason
        Struct.new(:id, :model, :service_tier, :choices).new(
          'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez',
          'gpt-5-nano-2025-08-07',
          :default,
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(nil),
              :stop
            )
          ]
        )
      ]

      # Simulate OpenAI::Internal::Stream by using an Enumerator that yields chunks
      # In production, this would be: response = client.request(..., stream: true)
      # which returns OpenAI::Internal::Stream[ChatCompletionChunk] that yields chunks when iterated
      stream = chunks.each
      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        stream,
        span,
        true
      )

      collected_chunks = wrapper.map do |chunk|
        chunk
      end

      _(collected_chunks.length).must_equal chunks.length
      _(span.attributes['gen_ai.response.id']).must_equal 'chatcmpl-Ce2zyewKHuOsD0esxDe6lp5ZqINez'
      _(span.attributes['gen_ai.response.model']).must_equal 'gpt-5-nano-2025-08-07'
      _(span.attributes['gen_ai.response.finish_reasons']).must_equal ['stop']
      _(span.attributes['openai.response.service_tier']).must_equal 'default'
    end

    it 'accumulates streaming content correctly' do
      span = tracer.start_root_span('test_span', kind: :client)

      chunks = [
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content, :role).new('Hello', :assistant),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(' world'),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new('!'),
              :stop
            )
          ]
        )
      ]

      stream = chunks.each
      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        stream,
        span,
        true
      )

      # Capture logger output to check logged events
      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output)

      wrapper.each { |_chunk| }

      OpenTelemetry.logger = original_logger

      logged_message = logger_output.string
      _(logged_message).must_include 'gen_ai.choice'
      _(logged_message).must_include 'openai'
      _(logged_message).must_include 'stop'
      _(logged_message).must_include 'Hello world!'
    end

    it 'handles streaming with usage information' do
      span = tracer.start_root_span('test_span', kind: :client)

      chunks = [
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content, :role).new('Hello', :assistant),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :choices, :usage).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(nil),
              :stop
            )
          ],
          Struct.new(:prompt_tokens, :completion_tokens).new(10, 5)
        )
      ]

      stream = chunks.each
      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        stream,
        span,
        false
      )

      wrapper.each { |_chunk| }

      _(span.attributes['gen_ai.usage.input_tokens']).must_equal 10
      _(span.attributes['gen_ai.usage.output_tokens']).must_equal 5
    end

    it 'handles streaming with tool calls' do
      span = tracer.start_root_span('test_span', kind: :client)

      chunks = [
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:role, :tool_calls).new(
                :assistant,
                [
                  Struct.new(:index, :id, :function).new(
                    0,
                    'call_123',
                    Struct.new(:name, :arguments).new('get_weather', '{"loc')
                  )
                ]
              ),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:tool_calls).new(
                [
                  Struct.new(:index, :function).new(
                    0,
                    Struct.new(:arguments).new('ation":"NYC"}')
                  )
                ]
              ),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(nil),
              :tool_calls
            )
          ]
        )
      ]

      stream = chunks.each
      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        stream,
        span,
        true
      )

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output)

      wrapper.each { |_chunk| }

      OpenTelemetry.logger = original_logger

      logged_message = logger_output.string
      _(logged_message).must_include 'tool_calls'
      _(logged_message).must_include 'get_weather'
      _(logged_message).must_include 'location'
      _(logged_message).must_include 'NYC'
    end

    it 'handles multiple choices in streaming' do
      span = tracer.start_root_span('test_span', kind: :client)

      chunks = [
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content, :role).new('Choice 1', :assistant),
              nil
            ),
            Struct.new(:index, :delta, :finish_reason).new(
              1,
              Struct.new(:content, :role).new('Choice 2', :assistant),
              nil
            )
          ]
        ),
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content).new(nil),
              :stop
            ),
            Struct.new(:index, :delta, :finish_reason).new(
              1,
              Struct.new(:content).new(nil),
              :stop
            )
          ]
        )
      ]

      stream = chunks.each
      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        stream,
        span,
        true
      )

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output)

      wrapper.each { |_chunk| }

      OpenTelemetry.logger = original_logger

      _(span.attributes['gen_ai.response.finish_reasons']).must_equal %w[stop stop]
      logged_message = logger_output.string
      _(logged_message).must_include 'Choice 1'
      _(logged_message).must_include 'Choice 2'
    end

    it 'handles errors during streaming' do
      span = tracer.start_root_span('test_span', kind: :client)

      error_stream = Enumerator.new do |yielder|
        yielder << Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content, :role).new('Hello', :assistant),
              nil
            )
          ]
        )
        raise StandardError, 'Stream error'
      end

      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        error_stream,
        span,
        false
      )

      assert_raises(StandardError) do
        wrapper.each { |_chunk| }
      end

      _(spans.length).must_equal 1
      _(spans.first.name).must_equal 'test_span'
      _(span.attributes['error.type']).must_equal 'StandardError'
      _(span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
    end

    it 'finishes span in ensure block even if error occurs' do
      span = tracer.start_root_span('test_span', kind: :client)

      error_stream = Enumerator.new do
        raise StandardError, 'Test error'
      end

      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        error_stream,
        span,
        false
      )

      assert_raises(StandardError) do
        wrapper.each { |_chunk| }
      end

      # Span should be finished even with error
      _(spans.length).must_equal 1
      _(spans.first.name).must_equal 'test_span'
      _(spans.first.attributes['error.type']).must_equal 'StandardError'
    end

    it 'does not log content when capture_content is false' do
      span = tracer.start_root_span('test_span', kind: :client)

      chunks = [
        Struct.new(:id, :model, :choices).new(
          'chatcmpl-123',
          'gpt-4',
          [
            Struct.new(:index, :delta, :finish_reason).new(
              0,
              Struct.new(:content, :role).new('Secret content', :assistant),
              :stop
            )
          ]
        )
      ]

      stream = chunks.each
      wrapper = OpenTelemetry::Instrumentation::OpenAI::Patches::StreamWrapper.new(
        stream,
        span,
        false # capture_content disabled
      )

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output)

      wrapper.each { |_chunk| }

      OpenTelemetry.logger = original_logger

      logged_message = logger_output.string
      _(logged_message).must_be_empty
    end
  end
end

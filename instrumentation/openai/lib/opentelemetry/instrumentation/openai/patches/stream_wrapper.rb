# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'utils'

module OpenTelemetry
  module Instrumentation
    module OpenAI
      module Patches
        # Stream wrapper for chat completion streaming
        class StreamWrapper
          include Enumerable
          include Utils

          attr_reader :stream, :span, :capture_content

          def initialize(stream, span, capture_content, start_time = nil)
            @stream = stream
            @span = span
            @capture_content = capture_content
            @start_time = start_time
            @time_to_first_chunk = nil
            @response_id = nil
            @response_model = nil
            @service_tier = nil
            @finish_reasons = []
            @prompt_tokens = 0
            @completion_tokens = 0
            @cached_tokens = nil
            @reasoning_tokens = nil
            @choice_buffers = []
            @span_started = true
          end

          # Iterates over streaming events, processing each chunk and yielding it to the caller.
          def each(&)
            @stream.each do |event|
              process_event(event)
              yield(event) if block_given?
            end
          rescue StandardError => e
            handle_error(e)
            raise
          ensure
            cleanup
          end

          private

          # @param chunk [OpenAI::Models::Chat::ChatCompletionChunk]
          def process_event(chunk)
            record_time_to_first_chunk
            response_metadata(chunk)
            build_streaming_response(chunk)
            usage(chunk)
          end

          def record_time_to_first_chunk
            return unless @start_time
            return if @time_to_first_chunk

            @time_to_first_chunk = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
          end

          def response_metadata(chunk)
            @response_model ||= chunk.model if chunk.respond_to?(:model)
            @response_id ||= chunk.id if chunk.respond_to?(:id)
            @service_tier ||= chunk.service_tier if chunk.respond_to?(:service_tier)
          end

          def build_streaming_response(chunk)
            return unless chunk.respond_to?(:choices) && chunk.choices

            chunk.choices.each do |choice|
              next unless choice.respond_to?(:delta) && choice.delta

              # Ensure we have enough choice buffers
              index = choice.respond_to?(:index) ? choice.index : 0
              @choice_buffers << ChoiceBuffer.new(@choice_buffers.size) while @choice_buffers.size <= index

              buffer = @choice_buffers[index]
              buffer.finish_reason = choice.finish_reason if choice.respond_to?(:finish_reason) && choice.finish_reason

              delta = choice.delta
              buffer.append_content(delta.content) if delta.respond_to?(:content) && delta.content
              buffer.append_tool_calls(delta.tool_calls) if delta.respond_to?(:tool_calls) && delta.tool_calls
            end
          end

          def usage(chunk)
            return unless chunk.respond_to?(:usage) && chunk.usage

            usage = chunk.usage
            @completion_tokens = usage.completion_tokens if usage.respond_to?(:completion_tokens)
            @prompt_tokens = usage.prompt_tokens if usage.respond_to?(:prompt_tokens)

            @cached_tokens = usage.prompt_tokens_details.cached_tokens if usage.respond_to?(:prompt_tokens_details) && usage.prompt_tokens_details.respond_to?(:cached_tokens)

            return unless usage.respond_to?(:completion_tokens_details) && usage.completion_tokens_details.respond_to?(:reasoning_tokens)

            @reasoning_tokens = usage.completion_tokens_details.reasoning_tokens
          end

          def cleanup
            return unless @span_started

            # Set final attributes only if span is still recording
            if @span.recording?
              finish_reasons = @choice_buffers.map { |x| x.finish_reason.to_s }
              attributes = {
                'gen_ai.response.model' => @response_model,
                'gen_ai.response.id' => @response_id,
                'gen_ai.usage.input_tokens' => @prompt_tokens.positive? ? @prompt_tokens : nil,
                'gen_ai.usage.output_tokens' => @completion_tokens.positive? ? @completion_tokens : nil,
                'gen_ai.usage.cache_read.input_tokens' => @cached_tokens,
                'gen_ai.usage.reasoning.output_tokens' => @reasoning_tokens,
                'gen_ai.response.finish_reasons' => finish_reasons.any? ? finish_reasons : nil,
                'gen_ai.response.time_to_first_chunk' => @time_to_first_chunk,
                'openai.response.service_tier' => @service_tier.to_s
              }.compact
              @span.add_attributes(attributes)
            end

            # Emit structured log events for each choice (not span events)
            if @capture_content
              @choice_buffers.each do |buffer|
                event = buffer.to_log_event
                log_structured_event(event)
              end
            end
          ensure
            @span.finish
            @span_started = false
          end

          def handle_error(error)
            @span.set_attribute('error.type', error.class.name)
            @span.record_exception(error)
            @span.status = OpenTelemetry::Trace::Status.error(error.message)
          end

          # Buffer for accumulating streaming choice data
          class ChoiceBuffer
            attr_accessor :finish_reason
            attr_reader :index, :text_content, :tool_call_buffers

            def initialize(index)
              @index = index
              @text_content = []
              @tool_call_buffers = []
              @finish_reason = nil
            end

            # Appends a content chunk to the text buffer.
            def append_content(content)
              @text_content << content if content
            end

            # Appends streaming tool call deltas to their respective buffers.
            def append_tool_calls(tool_calls)
              tool_calls.each do |tool_call|
                # Find or create tool call buffer
                buffer = @tool_call_buffers.find { |b| b.index == tool_call.index } if tool_call.respond_to?(:index)

                if buffer.nil?
                  tc_index = tool_call.respond_to?(:index) ? tool_call.index : @tool_call_buffers.size
                  buffer = ToolCallBuffer.new(tc_index)
                  @tool_call_buffers << buffer
                end

                buffer.append(tool_call)
              end
            end

            # Converts the accumulated choice buffer into a structured log event hash.
            def to_log_event
              body = {
                index: @index,
                finish_reason: @finish_reason&.to_s || 'error',
                message: {
                  role: 'assistant'
                }
              }

              body[:message][:content] = @text_content.join if @text_content.any?

              if @tool_call_buffers.any?
                tool_calls = @tool_call_buffers.map(&:to_hash)
                body[:message][:tool_calls] = tool_calls
              end

              {
                event_name: 'gen_ai.choice',
                attributes: {
                  'gen_ai.provider.name' => 'openai'
                },
                body: body
              }
            end
          end

          # Buffer for accumulating tool call data
          class ToolCallBuffer
            attr_reader :index

            def initialize(index)
              @index = index
              @tool_call_id = nil
              @function_name = nil
              @arguments = []
            end

            # Accumulates tool call delta data into the buffer.
            def append(tool_call)
              @tool_call_id ||= tool_call.id if tool_call.respond_to?(:id)

              return unless tool_call.respond_to?(:function) && tool_call.function

              function = tool_call.function
              @function_name ||= function.name if function.respond_to?(:name)
              @arguments << function.arguments if function.respond_to?(:arguments) && function.arguments
            end

            # Serializes the accumulated tool call buffer to a hash.
            def to_hash
              {
                id: @tool_call_id,
                type: 'function',
                function: {
                  name: @function_name,
                  arguments: @arguments.join
                }
              }
            end
          end
        end
      end
    end
  end
end

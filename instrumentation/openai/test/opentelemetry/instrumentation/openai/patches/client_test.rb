# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/openai'
require_relative '../../../../../lib/opentelemetry/instrumentation/openai/patches/client'

describe OpenTelemetry::Instrumentation::OpenAI::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::OpenAI::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:client_span) { spans.first }

  before do
    exporter.reset
    LOG_EXPORTER.reset
    instrumentation.install
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'chat completions via client.request' do
    let(:model) { 'gpt-4' }
    let(:messages) { [{ role: 'user', content: 'Hello!' }] }
    let(:response_body) do
      {
        id: 'chatcmpl-123',
        object: 'chat.completion',
        created: 1_677_652_288,
        model: 'gpt-4-0613',
        choices: [
          {
            index: 0,
            message: {
              role: 'assistant',
              content: 'Hello! How can I assist you today?'
            },
            finish_reason: 'stop'
          }
        ],
        usage: {
          prompt_tokens: 10,
          completion_tokens: 20,
          total_tokens: 30,
          prompt_tokens_details: { cached_tokens: 5 },
          completion_tokens_details: { reasoning_tokens: 8 }
        }
      }
    end

    before do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'creates span with basic attributes for chat completions request' do
      client = OpenAI::Client.new(api_key: 'test-token')
      client.chat.completions.create(
        model: model,
        messages: messages
      )

      _(client_span).wont_be_nil
      _(client_span.name).must_include 'chat'
      _(client_span.kind).must_equal :client

      _(client_span.attributes['gen_ai.operation.name']).must_equal 'chat'
      _(client_span.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(client_span.attributes['gen_ai.request.model']).must_equal model
      _(client_span.attributes['server.address']).must_equal 'api.openai.com'
      _(client_span.attributes['server.port']).must_equal 443
      _(client_span.attributes['url.path']).must_equal 'chat/completions'
      _(client_span.attributes['openai.api.type']).must_equal 'chat_completions'
      _(client_span.attributes['gen_ai.response.model']).must_equal 'gpt-4-0613'
      _(client_span.attributes['gen_ai.response.id']).must_equal 'chatcmpl-123'
      _(client_span.attributes['gen_ai.response.finish_reasons']).must_equal ['stop']
      _(client_span.attributes['gen_ai.usage.input_tokens']).must_equal 10
      _(client_span.attributes['gen_ai.usage.output_tokens']).must_equal 20
      _(client_span.attributes['gen_ai.usage.total_tokens']).must_equal 30
      _(client_span.attributes['gen_ai.usage.cache_read.input_tokens']).must_equal 5
      _(client_span.attributes['gen_ai.usage.reasoning.output_tokens']).must_equal 8
    end

    it 'sets optional chat completion parameters' do
      client = OpenAI::Client.new(api_key: 'test-token')
      client.chat.completions.create(
        model: model,
        messages: messages,
        temperature: 0.7,
        max_tokens: 100,
        top_p: 0.9,
        frequency_penalty: 0.5,
        presence_penalty: 0.3,
        seed: 42
      )

      _(client_span.attributes['gen_ai.request.temperature']).must_equal 0.7
      _(client_span.attributes['gen_ai.request.max_tokens']).must_equal 100
      _(client_span.attributes['gen_ai.request.top_p']).must_equal 0.9
      _(client_span.attributes['gen_ai.request.frequency_penalty']).must_equal 0.5
      _(client_span.attributes['gen_ai.request.presence_penalty']).must_equal 0.3
      _(client_span.attributes['gen_ai.request.seed']).must_equal 42
    end

    it 'sets reasoning level from reasoning_effort' do
      client = OpenAI::Client.new(api_key: 'test-token')
      client.chat.completions.create(
        model: model,
        messages: messages,
        reasoning_effort: :high
      )

      _(client_span.attributes['gen_ai.request.reasoning.level']).must_equal 'high'
    end

    it 'captures message content when enabled' do
      # Content capture is emitted as log records through the Logs API,
      # not as span events.
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install
      instrumentation.config[:capture_content] = true

      client = OpenAI::Client.new(api_key: 'test-token')
      client.chat.completions.create(
        model: model,
        messages: messages
      )

      _(client_span).wont_be_nil

      log_records = LOG_EXPORTER.emitted_log_records
      event_names = log_records.map(&:event_name)
      _(event_names).must_include 'gen_ai.user.message'
      _(event_names).must_include 'gen_ai.choice'

      user_message = log_records.find { |r| r.event_name == 'gen_ai.user.message' }
      _(user_message.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(user_message.body[:content]).must_equal 'Hello!'

      choice = log_records.find { |r| r.event_name == 'gen_ai.choice' }
      _(choice.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(choice.body[:message][:content]).must_equal 'Hello! How can I assist you today?'
      _(choice.body[:finish_reason]).must_equal 'stop'
    end
  end

  describe 'streaming chat completions via client.request' do
    let(:model) { 'gpt-4' }
    let(:messages) { [{ role: 'user', content: 'Hello!' }] }
    let(:sse_body) do
      <<~SSE
        data: {"id":"chatcmpl-stream-1","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4-0613","choices":[{"index":0,"delta":{"role":"assistant","content":"Hi"},"finish_reason":null}]}

        data: {"id":"chatcmpl-stream-1","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4-0613","choices":[{"index":0,"delta":{"content":"!"},"finish_reason":"stop"}]}

        data: [DONE]

      SSE
    end

    before do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 200, body: sse_body, headers: { 'Content-Type' => 'text/event-stream' })
    end

    it 'sets gen_ai.request.stream and time_to_first_chunk for streaming requests' do
      client = OpenAI::Client.new(api_key: 'test-token')
      stream = client.chat.completions.stream_raw(
        model: model,
        messages: messages
      )
      stream.each { |_chunk| }

      _(client_span).wont_be_nil
      _(client_span.attributes['gen_ai.operation.name']).must_equal 'chat'
      _(client_span.attributes['gen_ai.request.stream']).must_equal true
      _(client_span.attributes['gen_ai.response.finish_reasons']).must_equal ['stop']
      _(client_span.attributes).must_include 'gen_ai.response.time_to_first_chunk'
      _(client_span.attributes['gen_ai.response.time_to_first_chunk']).must_be :>=, 0
    end
  end

  describe 'embeddings via client.request' do
    let(:model) { 'text-embedding-ada-002' }
    let(:input_text) { 'The quick brown fox jumps over the lazy dog.' }
    let(:response_body) do
      {
        object: 'list',
        data: [
          {
            object: 'embedding',
            embedding: Array.new(1536) { rand },
            index: 0
          }
        ],
        model: 'text-embedding-ada-002-v2',
        usage: {
          prompt_tokens: 10,
          total_tokens: 10
        }
      }
    end

    before do
      stub_request(:post, 'https://api.openai.com/v1/embeddings')
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'creates a span for embeddings request' do
      client = OpenAI::Client.new(api_key: 'test-token')
      client.embeddings.create(
        model: model,
        input: input_text
      )

      _(client_span).wont_be_nil
      _(client_span.name).must_include 'embeddings'
      _(client_span.kind).must_equal :client

      _(client_span.attributes['gen_ai.operation.name']).must_equal 'embeddings'
      _(client_span.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(client_span.attributes['gen_ai.request.model']).must_equal model
      _(client_span.attributes['server.address']).must_equal 'api.openai.com'
      _(client_span.attributes['server.port']).must_equal 443
      _(client_span.attributes['url.path']).must_equal 'embeddings'
      _(client_span.attributes['gen_ai.output.type']).must_equal 'json'
      _(client_span.attributes['gen_ai.response.model']).must_equal 'text-embedding-ada-002-v2'
      _(client_span.attributes['gen_ai.embeddings.dimension.count']).must_equal 1536
      _(client_span.attributes['gen_ai.usage.input_tokens']).must_equal 10
      _(client_span.attributes['gen_ai.usage.total_tokens']).must_equal 10
    end

    it 'captures embedding input content when enabled' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install
      instrumentation.config[:capture_content] = true

      client = OpenAI::Client.new(api_key: 'test-token')
      client.embeddings.create(
        model: model,
        input: input_text
      )

      _(client_span).wont_be_nil

      log_records = LOG_EXPORTER.emitted_log_records
      user_message = log_records.find { |r| r.event_name == 'gen_ai.user.message' }
      _(user_message).wont_be_nil
      _(user_message.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(user_message.body[:content]).must_equal input_text
    end
  end

  describe 'error handling' do
    before do
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 500, body: { error: { message: 'Internal Server Error' } }.to_json)
    end

    it 'records exception and sets error status' do
      client = OpenAI::Client.new(api_key: 'test-token')

      begin
        client.chat.completions.create(
          model: 'gpt-4',
          messages: [{ role: 'user', content: 'Hello!' }]
        )
      rescue StandardError
        # Expected to raise
      end

      _(client_span).wont_be_nil
      _(client_span.status.code).must_equal OpenTelemetry::Trace::Status::ERROR
      _(client_span.status.description).must_include 'status'
      _(client_span.status.description).must_include '500'
      _(client_span.attributes['gen_ai.operation.name']).must_equal 'chat'
      _(client_span.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(client_span.attributes['gen_ai.request.model']).must_equal 'gpt-4'
      _(client_span.attributes['server.address']).must_equal 'api.openai.com'
      _(client_span.attributes['server.port']).must_equal 443
      _(client_span.attributes['url.path']).must_equal 'chat/completions'
      _(client_span.attributes['gen_ai.output.type']).must_equal 'text'
      _(client_span.attributes['error.type']).must_equal 'OpenAI::Errors::InternalServerError'

      exception_event = client_span.events.find { |event| event.name == 'exception' }
      _(exception_event).wont_be_nil
      _(exception_event.attributes['exception.type']).must_equal 'OpenAI::Errors::InternalServerError'
      _(exception_event.attributes['exception.message']).must_include 'status'
      _(exception_event.attributes['exception.message']).must_include '500'
    end
  end

  # Images generation is not in the default allowed_operation list
  # These tests are skipped. To enable, add 'images.generate' to allowed_operation config
  describe 'images generation via client.request (skipped - not in allowed_operation)' do
    let(:response_body) do
      {
        created: 1_677_652_288,
        data: [
          {
            url: 'https://example.com/image1.png'
          },
          {
            url: 'https://example.com/image2.png'
          }
        ]
      }
    end

    before do
      stub_request(:post, 'https://api.openai.com/v1/images/generations')
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'skip span creation for images generation' do
      client = OpenAI::Client.new(api_key: 'test-token')

      client.images.generate_stream_raw(
        prompt: 'A futuristic cityscape at night',
        model: 'gpt-image-1',
        n: 3, # Generate 3 different images
        partial_images: 4,
        size: '1536x1024', # Landscape
        output_format: :png,
        output_compression: 80
      )

      _(client_span).must_be_nil
    end
  end

  describe 'completions (legacy) via client.request' do
    let(:model) { 'gpt-3.5-turbo-instruct' }
    let(:prompt) { 'Once upon a time' }
    let(:response_body) do
      {
        id: 'cmpl-123',
        object: 'text_completion',
        created: 1_677_652_288,
        model: 'gpt-3.5-turbo-instruct',
        choices: [
          {
            text: ' there was a kingdom far away.',
            index: 0,
            finish_reason: 'stop'
          }
        ],
        usage: {
          prompt_tokens: 5,
          completion_tokens: 10,
          total_tokens: 15
        }
      }
    end

    before do
      stub_request(:post, 'https://api.openai.com/v1/completions')
        .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'creates a span for completions request' do
      client = OpenAI::Client.new(api_key: 'test-token')
      test_model = model
      test_prompt = prompt

      client.instance_eval do
        request(
          method: :post,
          path: 'completions',
          body: {
            model: test_model,
            prompt: test_prompt
          },
          model: OpenAI::Internal::Type::Unknown
        )
      end

      _(client_span).wont_be_nil
      _(client_span.attributes['gen_ai.operation.name']).must_equal 'completions'
      _(client_span.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(client_span.attributes['gen_ai.request.model']).must_equal model
      _(client_span.attributes['server.address']).must_equal 'api.openai.com'
      _(client_span.attributes['server.port']).must_equal 443
      _(client_span.attributes['url.path']).must_equal 'completions'
      _(client_span.attributes['openai.api.type']).must_equal 'chat_completions'
      _(client_span.attributes['gen_ai.output.type']).must_equal 'json'
    end

    it 'captures prompt content when enabled' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install
      instrumentation.config[:capture_content] = true

      client = OpenAI::Client.new(api_key: 'test-token')
      test_model = model
      test_prompt = prompt

      client.instance_eval do
        request(
          method: :post,
          path: 'completions',
          body: {
            model: test_model,
            prompt: test_prompt
          },
          model: OpenAI::Internal::Type::Unknown
        )
      end

      _(client_span).wont_be_nil

      user_message = LOG_EXPORTER.emitted_log_records.find { |r| r.event_name == 'gen_ai.user.message' }
      _(user_message).wont_be_nil
      _(user_message.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(user_message.body[:content]).must_include 'Once upon a time'
    end
  end
end

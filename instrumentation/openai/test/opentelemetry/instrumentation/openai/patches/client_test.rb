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
          total_tokens: 30
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
      _(client_span.attributes['http.request.method']).must_equal 'POST'
      _(client_span.attributes['url.path']).must_equal 'chat/completions'
      _(client_span.attributes['gen_ai.response.model']).must_equal 'gpt-4-0613'
      _(client_span.attributes['gen_ai.response.id']).must_equal 'chatcmpl-123'
      _(client_span.attributes['gen_ai.response.finish_reasons']).must_equal ['stop']
      _(client_span.attributes['gen_ai.usage.input_tokens']).must_equal 10
      _(client_span.attributes['gen_ai.usage.output_tokens']).must_equal 20
      _(client_span.attributes['gen_ai.usage.total_tokens']).must_equal 30
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

    it 'captures message content when enabled' do
      # Content capture logs to logger, not span events
      # This test verifies the span is created successfully
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install
      instrumentation.config[:capture_content] = true

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output, level: Logger::INFO)

      client = OpenAI::Client.new(api_key: 'test-token')
      client.chat.completions.create(
        model: model,
        messages: messages
      )

      OpenTelemetry.logger = original_logger

      _(client_span).wont_be_nil
      logged_message = logger_output.string

      _(logged_message).must_include 'gen_ai.user.message'
      _(logged_message).must_include 'Hello!'
      _(logged_message).must_include 'gen_ai.choice'
      _(logged_message).must_include 'Hello! How can I assist you today?'
      _(logged_message).must_include 'stop'
      _(logged_message).must_include 'gen_ai.provider.name'
      _(logged_message).must_include 'openai'
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
      _(client_span.attributes['http.request.method']).must_equal 'POST'
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

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output, level: Logger::INFO)

      client = OpenAI::Client.new(api_key: 'test-token')
      client.embeddings.create(
        model: model,
        input: input_text
      )

      OpenTelemetry.logger = original_logger

      _(client_span).wont_be_nil
      logged_message = logger_output.string
      _(logged_message).must_include 'gen_ai.user.message'
      _(logged_message).must_include 'gen_ai.provider.name'
      _(logged_message).must_include 'openai'
      _(logged_message).must_include 'content'
      _(logged_message).must_include 'The quick brown fox jumps over the lazy dog.'
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
      _(client_span.status.description).must_include 'status=>500'
      _(client_span.attributes['gen_ai.operation.name']).must_equal 'chat'
      _(client_span.attributes['gen_ai.provider.name']).must_equal 'openai'
      _(client_span.attributes['gen_ai.request.model']).must_equal 'gpt-4'
      _(client_span.attributes['server.address']).must_equal 'api.openai.com'
      _(client_span.attributes['server.port']).must_equal 443
      _(client_span.attributes['http.request.method']).must_equal 'POST'
      _(client_span.attributes['url.path']).must_equal 'chat/completions'
      _(client_span.attributes['gen_ai.output.type']).must_equal 'text'
      _(client_span.attributes['error.type']).must_equal 'OpenAI::Errors::InternalServerError'

      exception_event = client_span.events.find { |event| event.name == 'exception' }
      _(exception_event).wont_be_nil
      _(exception_event.attributes['exception.type']).must_equal 'OpenAI::Errors::InternalServerError'
      _(exception_event.attributes['exception.message']).must_include 'status=>500'
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
      _(client_span.attributes['http.request.method']).must_equal 'POST'
      _(client_span.attributes['url.path']).must_equal 'completions'
      _(client_span.attributes['gen_ai.output.type']).must_equal 'json'
    end

    it 'captures prompt content when enabled' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install
      instrumentation.config[:capture_content] = true

      logger_output = StringIO.new
      original_logger = OpenTelemetry.logger
      OpenTelemetry.logger = Logger.new(logger_output, level: Logger::INFO)

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

      OpenTelemetry.logger = original_logger

      _(client_span).wont_be_nil
      logged_message = logger_output.string
      _(logged_message).must_include 'gen_ai.user.message'
      _(logged_message).must_include 'openai'
      _(logged_message).must_include 'Once upon a time'
    end
  end
end

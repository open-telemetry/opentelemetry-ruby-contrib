# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'openai', '~> 0.66.1'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-logs-sdk'
  gem 'opentelemetry-instrumentation-openai', path: '../'
end

require 'openai'

ENV['OPENAI_API_KEY'] || abort('Missing OPENAI_API_KEY environment variable')

# Set this to capture chat/embedding message content as gen_ai log events.
ENV['OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT'] ||= 'true'

# Simple processors/exporters for demonstration purposes; a batch processor
# should be used in a production environment.
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
)
log_record_processor = OpenTelemetry::SDK::Logs::Export::SimpleLogRecordProcessor.new(
  OpenTelemetry::SDK::Logs::Export::ConsoleLogRecordExporter.new
)

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'opentelemetry-instrumentation-openai-example'
  c.use 'OpenTelemetry::Instrumentation::OpenAI'
  c.add_span_processor(span_processor)
  c.add_log_record_processor(log_record_processor)
end

class OpenAIClient
  MODEL_NAME = 'gpt-4o-mini'

  def initialize
    @client = OpenAI::Client.new(api_key: ENV.fetch('OPENAI_API_KEY'))
  end

  def chat_completion(messages, model: MODEL_NAME, max_tokens: 100)
    response = @client.chat.completions.create(
      model: model,
      messages: messages,
      max_completion_tokens: max_tokens
    )
    {
      content: response.choices[0].message.content,
      finish_reason: response.choices[0].finish_reason,
      usage: {
        prompt_tokens: response.usage.prompt_tokens,
        completion_tokens: response.usage.completion_tokens
      }
    }
  rescue OpenAI::Errors::APIError => e
    puts "Error: #{e.message}"
    nil
  end

  def chat_completion_stream(messages, model: MODEL_NAME, max_tokens: 100, &block)
    stream = @client.chat.completions.stream(
      model: model,
      messages: messages,
      max_completion_tokens: max_tokens,
      stream_options: { include_usage: true }
    )

    stream.each do |event|
      next unless event.type == :chunk

      content = event.chunk.choices[0]&.delta&.content
      finish_reason = event.chunk.choices[0]&.finish_reason
      block.call(content, finish_reason) if block_given?
    end
  rescue OpenAI::Errors::APIError => e
    puts "Error: #{e.message}"
  end

  def create_embedding(input, model: 'text-embedding-3-small', dimensions: nil)
    params = { model: model, input: input }
    params[:dimensions] = dimensions if dimensions

    response = @client.embeddings.create(**params)
    {
      embedding: response.data[0].embedding,
      usage: { prompt_tokens: response.usage.prompt_tokens }
    }
  rescue OpenAI::Errors::APIError => e
    puts "Error: #{e.message}"
    nil
  end
end

def demo_section(title)
  puts '=' * 50
  puts "=== #{title} ==="
  yield
  puts '=' * 50
  puts
end

client = OpenAIClient.new

demo_section('Basic Chat Completion') do
  messages = [{ role: 'user', content: 'What is 2 + 2?' }]
  response = client.chat_completion(messages)
  puts "Response: #{response[:content]}" if response
  puts "Usage: #{response[:usage]}" if response
end

demo_section('Streaming Chat Completion') do
  messages = [{ role: 'user', content: 'Count from 1 to 5.' }]
  print 'Response: '
  client.chat_completion_stream(messages) do |content, finish_reason|
    print content if content
    puts "\nFinish reason: #{finish_reason}" if finish_reason
  end
end

demo_section('Single Text Embedding') do
  response = client.create_embedding('Ruby is a dynamic programming language.')
  if response
    puts "Embedding dimensions: #{response[:embedding].length}"
    puts "Usage: #{response[:usage]}"
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative 'operation_name'
require_relative 'stream_wrapper'
require_relative 'utils'

module OpenTelemetry
  module Instrumentation
    module OpenAI
      module Patches
        # OpenAIClient Patch
        # rubocop:disable  Metrics/ModuleLength
        module Client
          include OperationName
          include Utils

          def request(req)
            operation_name = determine_operation_name(req)

            # Only instrument implemented/tested OpenAI operation
            return super unless config[:allowed_operation].include? operation_name

            model      = (req[:body][:model] || req[:body]['model']).to_s if req[:body].is_a? Hash
            span_name  = model.empty? ? operation_name : "#{operation_name} #{model}"
            attributes = extract_request_attributes(req, operation_name, model)

            # For streaming, start span manually so it stays open during iteration
            # Stream mode return OpenAI::Internal::Stream[OpenAI::Models::Chat::ChatCompletionChunk]
            if req[:stream]
              span = tracer.start_span(span_name, attributes: attributes, kind: :client)
              log_request_content(span, req) if config[:capture_content]

              response = super
              return StreamWrapper.new(response, span, config[:capture_content])
            end

            # Non-streaming path
            tracer.in_span(
              span_name,
              attributes: attributes,
              kind: :client
            ) do |span|
              # Log request details if content capture is enabled and
              log_request_content(span, req) if config[:capture_content]

              response = super
              handle_response(span, response, req)

              response
            rescue StandardError => e
              handle_span_exception(span, e)
              raise
            end
          end

          private

          def tracer
            OpenAI::Instrumentation.instance.tracer
          end

          def config
            OpenAI::Instrumentation.instance.config
          end

          # Extract comprehensive request attributes following semantic conventions
          def extract_request_attributes(req, operation_name, model)
            uri = begin
              URI.parse(req[:url])
            rescue StandardError
              nil
            end

            request_attributes = {
              'gen_ai.operation.name' => operation_name,
              'gen_ai.provider.name' => 'openai',
              'gen_ai.request.model' => model,
              'server.address' => uri&.host || 'api.openai.com',
              'server.port' => uri&.port || 443,
              'http.request.method' => req[:method].to_s.upcase,
              'url.path' => req[:path],
              'gen_ai.output.type' => get_output_type(operation_name)
            }.compact

            # Extract attributes from request body based on operation name
            merge_body_attributes!(request_attributes, req[:body], operation_name)

            request_attributes
          end

          # Since only chat and embedding is allowed, so we will only expect 'text' as output
          def get_output_type(operation_name)
            case operation_name
            when 'chat'
              'text'
            when 'images.generate', 'images.edit', 'images.variation'
              'image'
            when 'audio.transcription', 'audio.translation', 'audio.speech'
              'speech'
            else
              'json'
            end
          end

          # Merge body attributes based on operation type
          def merge_body_attributes!(attributes, body, operation_name)
            return unless body.is_a?(Hash)

            case operation_name
            when 'chat', 'completions'
              merge_chat_attributes!(attributes, body)
            when 'embeddings'
              merge_embeddings_attributes!(attributes, body)
            end
          end

          # Merge chat/completion specific attributes
          def merge_chat_attributes!(attributes, body)
            n_count = body[:n]
            stop_sequences = if body[:stop].is_a?(Array)
                               body[:stop]
                             else
                               (body[:stop] ? [body[:stop]] : nil)
                             end
            service_tier = body[:service_tier]&.to_s

            chat_attributes = {
              'gen_ai.request.temperature' => body[:temperature],
              'gen_ai.request.max_tokens' => body[:max_tokens] || body[:max_completion_tokens],
              'gen_ai.request.top_p' => body[:top_p],
              'gen_ai.request.frequency_penalty' => body[:frequency_penalty],
              'gen_ai.request.presence_penalty' => body[:presence_penalty],
              'gen_ai.request.seed' => body[:seed],
              'gen_ai.request.stop_sequences' => stop_sequences,
              'gen_ai.request.choice.count' => n_count && n_count != 1 ? n_count : nil,
              'openai.request.service_tier' => service_tier && service_tier != 'auto' ? service_tier : nil
            }.compact

            attributes.merge!(chat_attributes)
          end

          # Merge embeddings specific attributes
          def merge_embeddings_attributes!(attributes, body)
            encoding_formats = body[:encoding_format] ? [body[:encoding_format].to_s] : nil

            embeddings_attributes = {
              'gen_ai.request.encoding_formats' => encoding_formats
            }.compact

            attributes.merge!(embeddings_attributes)
          end

          # Log request content for debugging/monitoring
          def log_request_content(span, req)
            body = req[:body]
            return unless body.is_a?(Hash)

            if body[:messages].is_a?(Array)
              body[:messages].each do |message|
                event = message_to_log_event(message, capture_content: true)
                log_structured_event(event)
              end
            end

            if body[:input]
              input_text = body[:input].is_a?(Array) ? body[:input].join(', ') : body[:input].to_s
              event = {
                event_name: 'gen_ai.user.message',
                attributes: { 'gen_ai.provider.name' => 'openai' },
                body: { content: input_text }
              }
              log_structured_event(event)
            end

            return unless body[:prompt]

            prompt_text = body[:prompt].is_a?(Array) ? body[:prompt].join(', ') : body[:prompt].to_s
            event = {
              event_name: 'gen_ai.user.message',
              attributes: { 'gen_ai.provider.name' => 'openai' },
              body: { content: prompt_text }
            }
            log_structured_event(event)
          end

          # Handle different response types and extract telemetry data
          def handle_response(span, result, req)
            return unless span.recording?

            # Set basic response attributes (only for non-streaming responses with these methods)
            response_attributes = {
              'gen_ai.response.model' => result.respond_to?(:model) ? result.model : nil,
              'gen_ai.response.id' => result.respond_to?(:id) ? result.id : nil,
              'openai.response.service_tier' => result.respond_to?(:service_tier) ? result.service_tier&.to_s : nil,
              'openai.response.system_fingerprint' => result.respond_to?(:system_fingerprint) ? result.system_fingerprint : nil
            }.compact
            span.add_attributes(response_attributes)

            # Handle usage/token information
            set_usage_attributes(span, result.usage) if result.respond_to?(:usage) && result.usage

            # Handle different completion responses
            if result.respond_to?(:choices) && result.choices&.any?
              handle_chat_completion_response(span, result)
            elsif result.respond_to?(:data) && result.data&.any?
              handle_embeddings_response(span, result) if result.data.first.respond_to?(:embedding)
            end
          end

          # Handle chat completion response
          def handle_chat_completion_response(span, result)
            finish_reasons = result.choices.map { |x| x.finish_reason.to_s }
            span.set_attribute('gen_ai.response.finish_reasons', finish_reasons) if finish_reasons.any?

            return unless config[:capture_content]

            result.choices.each do |choice|
              event = choice_to_log_event(choice, capture_content: true)
              log_structured_event(event)
            end
          end

          # Handle embeddings response
          def handle_embeddings_response(span, result)
            embedding_dimensions = result.data.first.respond_to?(:embedding) ? result.data.first.embedding&.size : nil

            attributes = {
              'gen_ai.embeddings.dimension.count' => embedding_dimensions
            }.compact

            span.add_attributes(attributes)
          end

          # Set token usage attributes
          def set_usage_attributes(span, usage)
            usage_attributes = {
              'gen_ai.usage.input_tokens' => usage.respond_to?(:prompt_tokens) ? usage.prompt_tokens : nil,
              'gen_ai.usage.output_tokens' => usage.respond_to?(:completion_tokens) ? usage.completion_tokens : nil,
              'gen_ai.usage.total_tokens' => usage.respond_to?(:total_tokens) ? usage.total_tokens : nil
            }.compact

            span.add_attributes(usage_attributes)
          end

          # Handle span exception
          def handle_span_exception(span, error)
            span.set_attribute('error.type', error.class.name)
            span.record_exception(error)
            span.status = OpenTelemetry::Trace::Status.error(error.message)
            span.finish
          end
        end
        # rubocop:enable  Metrics/ModuleLength
      end
    end
  end
end

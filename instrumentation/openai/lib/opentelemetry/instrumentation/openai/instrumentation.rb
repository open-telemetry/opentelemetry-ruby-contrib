# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module OpenAI
      # The Instrumentation class contains logic to detect and install the Openai instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('0.35.2')
        ALLOWED_OPERATION = %w[chat completions embeddings].freeze

        install do |_config|
          require_dependencies
          determine_the_content_mode
          patch_client
        end

        present do
          defined?(::OpenAI)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        option :capture_content, default: false, validate: :boolean
        option :allowed_operation, default: ALLOWED_OPERATION, validate: :array

        private

        def gem_version
          ::OpenAI::VERSION
        end

        def determine_the_content_mode
          should_capture_content = ENV['OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT'].to_s.downcase == 'true'
          config[:capture_content] = should_capture_content
        end

        def require_dependencies
          require_relative 'patches/client'
        end

        # openai-ruby has chat.completions.{chat, stream_raw, stream}
        # there are a lot of path for openai api, but for openai-ruby, everything falls to @client.request
        # so we just instrument the @client.request should be enough
        # but if you want to get response, then
        # def request(req)
        #   span.add(req)
        #   response = super
        #   span.add(response)
        #   response
        # end

        # for the llm span attributes, two categories: chat and embedding.
        # all of them need operation name, ai system and request model (ai model)
        # chat needs temperature, erquest top p, max_tokens, prescent penalty frequency penalty, request seed, response format,
        # embedding needs dimensions and encoding format

        # for the trace and span, it emit user message as log, set response to response attributes if recording, return result
        # for streaming, openai-ruby request has the param: (stream: OpenAI::Internal::Stream,) may need really work on this because stream is tricky

        def patch_client
          ::OpenAI::Client.prepend(Patches::Client)
        end
      end
    end
  end
end

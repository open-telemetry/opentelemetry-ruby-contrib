# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module OpenAI
      # The Instrumentation class contains logic to detect and install the openai instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('0.35.2')
        ALLOWED_OPERATIONS = %w[chat completions embeddings].freeze

        install do |_config|
          require_dependencies
          determine_the_content_mode
          create_logger
          patch_client
        end

        present do
          defined?(::OpenAI)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        # Captures the content of prompts and responses (e.g. chat messages, inputs,
        # prompts, and tool call arguments) as structured `gen_ai` log records.
        # Disabled by default to avoid recording potentially sensitive data. When
        # enabled, message content is emitted through the OpenTelemetry Logs API
        # via the configured logger provider.
        #
        # This option is overridden at install time by the
        # `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` environment variable
        # (see #determine_the_content_mode).
        option :capture_content, default: false, validate: :boolean

        # The list of OpenAI operations to instrument. Only requests whose resolved
        # operation name is included here produce spans; all other operations pass
        # through untouched. Defaults to ALLOWED_OPERATIONS (chat, completions,
        # embeddings), the operations currently implemented and tested.
        option :allowed_operations, default: ALLOWED_OPERATIONS, validate: :array

        attr_reader :logger

        private

        def gem_version
          ::OpenAI::VERSION
        end

        def determine_the_content_mode
          env_value = ENV['OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT'].to_s
          config[:capture_content] = env_value.downcase == 'true' unless env_value.empty?
        end

        def require_dependencies
          require_relative 'patches/client'
        end

        def create_logger
          # Users must install the OpenTelemetry Logs API and SDK gems to
          # create log events. The Logs API is still unstable, unlike the
          # Traces API, so we require users to isntall it themselves.
          if defined?(OpenTelemetry::Logs) && defined?(OpenTelemetry::SDK::Logs)
            @logger = OpenTelemetry.logger_provider.logger(name: NAME, version: VERSION)
          elsif defined?(OpenTelemetry::Logs)
            # If there is no Logs SDK, we can still have a NOOP_LOGGER running
            # if the API is present.
            @logger = OpenTelemetry::Logs::LoggerProvider::NOOP_LOGGER
          end
        end

        def patch_client
          ::OpenAI::Client.prepend(Patches::Client)
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Sidekiq
      # The Instrumentation class contains logic to detect and install the Sidekiq
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('4.2.10')

        install do |_config|
          require_dependencies
          add_client_middleware
          add_server_middleware
          patch_on_startup
        end

        present do
          defined?(::Sidekiq)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        # @!group Instrumentation Options
        # @!macro
        #   @!method $1
        #   @instrumentation_option_default `:$2`
        #   @!scope class
        #
        #   Specify how the span names are set. Can be one of:
        #
        #   - `:queue` - the span names will be set to '<destination / queue name> <operation>'.
        #   - `:job_class` - the span names will be set to '<job class name> <operation>'.
        option :span_naming,                 default: :queue, validate: %I[job_class queue]
        #   Controls how the job's execution is traced and related
        #   to the trace where the job was enqueued. Can be one of:
        #
        #   - `:link` - the job will be executed in a separate trace. The
        #     initial span of the execution trace will be linked to the span that
        #     enqueued the job, via a Span Link.
        #   - `:child` - the job will be executed in the same logical trace, as a direct
        #     child of the span that enqueued the job.
        #   - `:none` - the job's execution will not be explicitly linked to the span that
        #     enqueued the job.
        option :propagation_style,           default: :link,  validate: %i[link child none]
        # @!macro
        #   @!method $1
        #   @instrumentation_option_default `:$2`
        #   @!scope class
        #   Allows tracing Sidekiq::Launcher#heartbeat.
        option :trace_launcher_heartbeat,    default: false, validate: :boolean
        # @!macro
        #   @!method $1
        #   @instrumentation_option_default $2
        #   @!scope class
        #   Allows tracing Sidekiq::Scheduled#enqueue.
        option :trace_poller_enqueue,        default: false, validate: :boolean
        # @!macro
        #   @!method $1
        #   @instrumentation_option_default $2
        #   @!scope class
        #   Allows trasing Sidekiq::Scheduled#wait
        option :trace_poller_wait,           default: false, validate: :boolean
        # @!macro
        #   @!method $1
        #   @instrumentation_option_default $2
        #   @!scope class
        #   Allows tracing Sidekiq::Processor#process_one.
        option :trace_processor_process_one, default: false, validate: :boolean
        # @!macro
        #   @!method $1
        #   @instrumentation_option_default $2
        #   @!scope class
        #   Sets service name of the remote service.
        option :peer_service,                default: nil,   validate: :string
        # @!endgroup

        private

        def gem_version
          Gem::Version.new(::Sidekiq::VERSION)
        end

        def require_dependencies
          require_relative 'middlewares/client/tracer_middleware'
          require_relative 'middlewares/server/tracer_middleware'

          require_relative 'patches/processor'
          require_relative 'patches/launcher'
          require_relative 'patches/poller'
        end

        def patch_on_startup
          ::Sidekiq.configure_server do |config|
            config.on(:startup) do
              ::Sidekiq::Processor.prepend(Patches::Processor)
              ::Sidekiq::Launcher.prepend(Patches::Launcher)
              ::Sidekiq::Scheduled::Poller.prepend(Patches::Poller)
            end

            config.on(:shutdown) do
              OpenTelemetry.tracer_provider.shutdown
            end
          end
        end

        def add_client_middleware
          ::Sidekiq.configure_client do |config|
            config.client_middleware do |chain|
              chain.prepend Middlewares::Client::TracerMiddleware
            end
          end
        end

        def add_server_middleware
          ::Sidekiq.configure_server do |config|
            config.client_middleware do |chain|
              chain.prepend Middlewares::Client::TracerMiddleware
            end
            config.server_middleware do |chain|
              chain.prepend Middlewares::Server::TracerMiddleware
            end
          end

          if defined?(::Sidekiq::Testing) # rubocop:disable Style/GuardClause
            ::Sidekiq::Testing.server_middleware do |chain|
              chain.prepend Middlewares::Server::TracerMiddleware
            end
          end
        end
      end
    end
  end
end

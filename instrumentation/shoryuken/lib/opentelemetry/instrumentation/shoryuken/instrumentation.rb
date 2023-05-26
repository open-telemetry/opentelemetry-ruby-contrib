# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Shoryuken
      # The Instrumentation class contains logic to detect and install the Sidekiq
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('5.3.0')

        install do |_config|
          require_dependencies
          add_server_middleware
          patch_on_startup
        end

        present do
          defined?(::Shoryuken)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        private

        def gem_version
          Gem::Version.new(::Shoryuken::VERSION)
        end

        def require_dependencies
          require_relative 'middlewares/server/tracer_middleware'

          require_relative 'patches/processor'
          require_relative 'patches/fetcher'
        end

        def patch_on_startup
          ::Shoryuken.configure_server do |config|
            config.on(:startup) do
              ::Shoryuken::Processor.prepend(Patches::Processor)
              ::Shoryuken::Fetcher.prepend(Patches::Fetcher)
            end

            config.on(:shutdown) do
              OpenTelemetry.tracer_provider.shutdown
            end
          end
        end

        def add_server_middleware
          ::Shoryuken.configure_server do |config|
            config.server_middleware do |chain|
              chain.add Middlewares::Server::TracerMiddleware
            end
          end
        end
      end
    end
  end
end

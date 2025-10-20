# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-instrumentation-rack'

module OpenTelemetry
  module Instrumentation
    module Twirp
      # The Instrumentation class contains logic to detect and install the Twirp instrumentation
      #
      # Installation and configuration of this instrumentation is done within the
      # {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry/SDK#configure-instance_method OpenTelemetry::SDK#configure}
      # block, calling {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use use()}
      # or {https://www.rubydoc.info/gems/opentelemetry-sdk/OpenTelemetry%2FSDK%2FConfigurator:use_all use_all()}.
      #
      # ## Configuration keys and options
      #
      # ### `:install_rack`
      #
      # Default is `true`. Specifies whether or not to install the Rack instrumentation as part of installing the Twirp instrumentation.
      # This is useful in cases where you want to manually specify where to insert the tracing middleware.
      #
      # @example Manually install Rack instrumentation.
      #   OpenTelemetry::SDK.configure do |c|
      #     c.use_all({
      #       'OpenTelemetry::Instrumentation::Rack' => { },
      #       'OpenTelemetry::Instrumentation::Twirp' => {
      #         install_rack: false
      #       },
      #     })
      #   end
      #
      # ### `:peer_service`
      #
      # Optionally set the `peer.service` attribute on client spans.
      #
      # @example Set peer service
      #   OpenTelemetry::SDK.configure do |c|
      #     c.use 'OpenTelemetry::Instrumentation::Twirp', {
      #       peer_service: 'twirp-backend'
      #     }
      #   end
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
          install_server(config)
        end

        option :install_rack, default: true, validate: :boolean
        option :peer_service, default: nil, validate: :string

        present do
          defined?(::Twirp)
        end

        private

        def require_dependencies
          require_relative 'patches/client'
          require_relative 'patches/service'
        end

        def patch_client
          ::Twirp::Client.prepend(Patches::Client)
        end

        def install_server(config)
          if config[:install_rack]
            OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.install({})
          end

          unless OpenTelemetry::Instrumentation::Rack::Instrumentation.instance.installed?
            OpenTelemetry.logger.warn('Rack instrumentation is required for Twirp server but not installed. Please see the docs for more details: https://opentelemetry.io/docs/languages/ruby/libraries/')
          end

          # Patch Service to inject middleware
          ::Twirp::Service.prepend(Patches::Service) if defined?(::Twirp::Service)
        end
      end
    end
  end
end

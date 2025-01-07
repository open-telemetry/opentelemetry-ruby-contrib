# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    # Extensions to Instrumentation::Base that handle metrics instruments.
    # The goal here is to allow metrics to be added gradually to instrumentation libraries,
    # without requiring that the metrics-sdk or metrics-api gems are present in the bundle
    # (if they are not, or if the metrics-api gem does not meet the minimum version requirement,
    # the no-op edition is installed.)
    module Metrics
      METER_TYPES = %i[
        counter
        observable_counter
        histogram
        gauge
        observable_gauge
        up_down_counter
        observable_up_down_counter
      ].freeze

      def self.prepended(base)
        base.prepend(Compatibility)
        base.extend(Compatibility)
        base.extend(Registration)

        if base.metrics_compatible?
          base.prepend(Extensions)
        else
          base.prepend(NoopExtensions)
        end
      end

      # Methods to check whether the metrics API is defined
      # and is a compatible version
      module Compatibility
        METRICS_API_MINIMUM_GEM_VERSION = Gem::Version.new('0.2.0')

        def metrics_defined?
          defined?(OpenTelemetry::Metrics)
        end

        def metrics_compatible?
          metrics_defined? && Gem.loaded_specs['opentelemetry-metrics-api'].version >= METRICS_API_MINIMUM_GEM_VERSION
        end

        extend(self)
      end

      # class-level methods to declare and register metrics instruments.
      # This can be extended even if metrics is not active or present.
      module Registration
        METER_TYPES.each do |instrument_kind|
          define_method(instrument_kind) do |name, **opts, &block|
            opts[:callback] ||= block if block
            register_instrument(instrument_kind, name, **opts)
          end
        end

        def register_instrument(kind, name, **opts)
          key = [kind, name]
          if instrument_configs.key?(key)
            warn("Duplicate instrument configured for #{self}: #{key.inspect}")
          else
            instrument_configs[key] = opts
          end
        end

        def instrument_configs
          @instrument_configs ||= {}
        end
      end

      # No-op instance methods for metrics instruments.
      module NoopExtensions
        METER_TYPES.each do |kind|
          define_method(kind) {} # rubocop: disable Lint/EmptyBlock
        end

        def with_meter; end

        def metrics_enabled?
          false
        end
      end

      # Instance methods for metrics instruments.
      module Extensions
        %i[
          counter
          observable_counter
          histogram
          gauge
          observable_gauge
          up_down_counter
          observable_up_down_counter
        ].each do |kind|
          define_method(kind) do |name|
            get_metrics_instrument(kind, name)
          end
        end

        # This is based on a variety of factors, and should be invalidated when @config changes.
        # It should be explicitly set in `prepare_install` for now.
        def metrics_enabled?
          !!@metrics_enabled
        end

        # @api private
        # ONLY yields if the meter is enabled.
        def with_meter
          yield @meter if metrics_enabled?
        end

        private

        def compute_metrics_enabled
          return false unless metrics_compatible?
          return false if metrics_disabled_by_env_var?

          !!@config[:metrics] || metrics_enabled_by_env_var?
        end

        # Checks if this instrumentation's metrics are enabled by env var.
        # This follows the conventions as outlined above, using `_METRICS_ENABLED` as a suffix.
        # Unlike INSTRUMENTATION_*_ENABLED variables, these are explicitly opt-in (i.e.
        # if the variable is unset, and `metrics: true` is not in the instrumentation's config,
        # the metrics will not be enabled)
        def metrics_enabled_by_env_var?
          ENV.key?(metrics_env_var_name) && ENV[metrics_env_var_name] != 'false'
        end

        def metrics_disabled_by_env_var?
          ENV[metrics_env_var_name] == 'false'
        end

        def metrics_env_var_name
          @metrics_env_var_name ||=
            begin
              var_name = name.dup
              var_name.upcase!
              var_name.gsub!('::', '_')
              var_name.gsub!('OPENTELEMETRY_', 'OTEL_RUBY_')
              var_name << '_METRICS_ENABLED'
              var_name
            end
        end

        def prepare_install
          @metrics_enabled = compute_metrics_enabled
          if metrics_defined?
            @metrics_instruments = {}
            @instrument_mutex = Mutex.new
          end

          @meter = OpenTelemetry.meter_provider.meter(name, version: version) if metrics_enabled?

          super
        end

        def get_metrics_instrument(kind, name)
          # TODO: we should probably return *something*
          # if metrics is not enabled, but if the api is undefined,
          # it's unclear exactly what would be suitable.
          # For now, there are no public methods that call this
          # if metrics isn't defined.
          return unless metrics_defined?

          @metrics_instruments.fetch([kind, name]) do |key|
            @instrument_mutex.synchronize do
              @metrics_instruments[key] ||= create_configured_instrument(kind, name)
            end
          end
        end

        def create_configured_instrument(kind, name)
          config = self.class.instrument_configs[[kind, name]]

          if config.nil?
            Kernel.warn("unconfigured instrument requested: #{kind} of '#{name}'")
            return
          end

          meter.public_send(:"create_#{kind}", name, **config)
        end
      end
    end
  end
end

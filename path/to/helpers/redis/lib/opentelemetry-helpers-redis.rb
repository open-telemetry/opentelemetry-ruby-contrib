# -*- coding: utf-8 -*-

require 'opentelemetry/api'
require 'opentelemetry/exporter/otlp/http'
require 'opentelemetry/sdk'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/resource'

module OpenTelemetry
  module Helpers
    module Redis
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def instrument
          OpenTelemetry::Instrumentation::Redis.instrument(self)
        end
      end

      def self.instrumentation
        @instrumentation ||= OpenTelemetry::Instrumentation::Redis.instrumentation
      end
    end
  end
end
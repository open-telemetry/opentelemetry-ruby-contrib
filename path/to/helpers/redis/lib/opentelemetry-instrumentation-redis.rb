# -*- coding: utf-8 -*-

require 'opentelemetry/api'
require 'opentelemetry/exporter/otlp/http'
require 'opentelemetry/sdk'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/resource'

module OpenTelemetry
  module Instrumentation
    module Redis
      def self.instrument(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def connect
          OpenTelemetry::Instrumentation::Redis.instrumentation.connect(self)
        end

        def set(key, value)
          OpenTelemetry::Instrumentation::Redis.instrumentation.set(self, key, value)
        end

        def get(key)
          OpenTelemetry::Instrumentation::Redis.instrumentation.get(self, key)
        end

        def incr(key)
          OpenTelemetry::Instrumentation::Redis.instrumentation.incr(self, key)
        end

        def transaction
          OpenTelemetry::Instrumentation::Redis.instrumentation.transaction(self)
        end
      end

      def self.instrumentation
        @instrumentation ||= OpenTelemetry::Instrumentation::Redis::Instrumentation.new
      end
    end
  end
end
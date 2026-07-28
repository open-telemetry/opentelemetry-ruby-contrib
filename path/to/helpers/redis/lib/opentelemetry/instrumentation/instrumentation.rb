# -*- coding: utf-8 -*-

require 'opentelemetry/api'
require 'opentelemetry/exporter/otlp/http'
require 'opentelemetry/sdk'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/resource'

module OpenTelemetry
  module Instrumentation
    module Redis
      class Instrumentation
        def initialize
          @span = nil
        end

        def connect(base)
          base.span = OpenTelemetry::Api::Span.new
          base.span.name = 'connect'
          base.span.start
        end

        def set(base, key, value)
          base.span = OpenTelemetry::Api::Span.new
          base.span.name = 'set'
          base.span.start
          base.span.add_attribute('key', key)
          base.span.add_attribute('value', value)
          base.span.end
        end

        def get(base, key)
          base.span = OpenTelemetry::Api::Span.new
          base.span.name = 'get'
          base.span.start
          base.span.add_attribute('key', key)
          base.span.end
        end

        def incr(base, key)
          base.span = OpenTelemetry::Api::Span.new
          base.span.name = 'incr'
          base.span.start
          base.span.add_attribute('key', key)
          base.span.end
        end

        def transaction(base)
          base.span = OpenTelemetry::Api::Span.new
          base.span.name = 'transaction'
          base.span.start
          base.span.end
        end
      end
    end
  end
end
# frozen_string_literal: true

require 'sequel'

# Sequel: The Database Toolkit for Ruby
module Sequel
  # The Sequel::OpenTelemetry extension
  #
  # @example Simple usage
  #
  #     require 'sequel-opentelemetry'
  #     DB.extension :opentelemetry
  #
  # Related module: Sequel::OpenTelemetry
  module OpenTelemetry
    def tracer
      ::OpenTelemetry::Instrumentation::Sequel::Instrumentation.instance.tracer
    end

    def trace_execute(super_method, sequel_method, sql, options, &block)
      response = nil
      attributes = {
        ::OpenTelemetry::SemanticConventions::Trace::DB_NAME => opts[:database],
        ::OpenTelemetry::SemanticConventions::Trace::DB_SYSTEM => database_type.to_s
      }
      attributes['server.address'] = opts[:host] if opts[:host]
      attributes['sequel.timezone'] = timezone if timezone

      tracer.in_span("sequel.#{sequel_method}", attributes: attributes) do
        response = super_method.call(sql, options, &block)
      end
      response
    end

    def execute(sql, options = ::Sequel::OPTS, &block)
      trace_execute(proc { super(sql, options, &block) }, 'execute', sql, options, &block)
    end

    def execute_dui(sql, options = ::Sequel::OPTS, &block)
      trace_execute(proc { super(sql, options, &block) }, 'execute_dui', sql, options, &block)
    end

    def execute_insert(sql, options = ::Sequel::OPTS, &block)
      trace_execute(proc { super(sql, options, &block) }, 'execute_insert', sql, options, &block)
    end
  end
  Database.register_extension(:opentelemetry, OpenTelemetry)
end

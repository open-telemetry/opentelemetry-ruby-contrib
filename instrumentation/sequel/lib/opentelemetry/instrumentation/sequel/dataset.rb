# frozen_string_literal: true

require_relative 'ext'
require_relative 'utils'

module OpenTelemetry
  module Instrumentation
    module Sequel
      # Adds instrumentation to Sequel::Dataset
      module Dataset
        def self.included(base)
          base.prepend(InstanceMethods)
        end

        # Instance methods for instrumenting Sequel::Dataset
        module InstanceMethods
          def execute(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          def execute_ddl(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          def execute_dui(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          def execute_insert(sql, options = ::Sequel::OPTS, &block)
            trace_execute(proc { super(sql, options, &block) }, sql, options, &block)
          end

          private

          def tracer
            Sequel::Instrumentation.instance.tracer
          end

          def config
            Sequel::Instrumentation.instance.config
          end

          def trace_execute(super_method, sql, options, &block)
            opts = Utils.parse_opts(sql, options, db.opts, self)
            response = nil

            tracer.in_span(Ext::SPAN_QUERY) do |span|
              span.name = opts[:query]
              Utils.set_common_attributes(span, db)
              span.set_attribute(Ext::TAG_DB_VENDOR, adapter_name)
              span.set_attribute(Ext::TAG_PREPARED_NAME, opts[:prepared_name]) if opts[:prepared_name]
              response = super_method.call(sql, options, &block)
            end
            response
          end

          def adapter_name
            Utils.adapter_name(db)
          end
        end
      end
    end
  end
end

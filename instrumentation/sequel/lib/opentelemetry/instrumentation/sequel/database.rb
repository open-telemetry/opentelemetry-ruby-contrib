# frozen_string_literal: true

require_relative 'ext'
require_relative 'utils'

module OpenTelemetry
  module Instrumentation
    module Sequel
      # Adds instrumentation to Sequel::Database
      module Database
        def self.included(base)
          base.prepend(InstanceMethods)
        end

        # Instance methods for instrumenting Sequel::Database
        module InstanceMethods
          def run(sql, options = ::Sequel::OPTS)
            opts = parse_opts(sql, options)

            response = nil

            tracer.in_span(Ext::SPAN_QUERY) do |span|
              span.service = config[:service_name]
              span.set_attribute('query', opts[:query])
              span.set_attribute('component', Tracing::Metadata::Ext::SQL::TYPE)
              Utils.set_common_tags(span, self)
              span.set_attribute(Ext::TAG_DB_VENDOR, adapter_name)
              response = super(sql, options)
            end
            response
          end

          private

          def tracer
            Sequel::Instrumentation.instance.tracer
            # OpenTelemetry.tracer_provider.tracer("test")
          end

          def config
            Sequel::Instrumentation.instance.config
          end

          def adapter_name
            Utils.adapter_name(self)
          end

          def parse_opts(sql, opts)
            db_opts = if ::Sequel::VERSION < '3.41.0' && self.class.to_s !~ /Dataset$/
                        @opts
                      elsif instance_variable_defined?(:@pool) && @pool
                        @pool.db.opts
                      end
            sql = sql.is_a?(::Sequel::SQL::Expression) ? literal(sql) : sql.to_s

            Utils.parse_opts(sql, opts, db_opts)
          end
        end
      end
    end
  end
end

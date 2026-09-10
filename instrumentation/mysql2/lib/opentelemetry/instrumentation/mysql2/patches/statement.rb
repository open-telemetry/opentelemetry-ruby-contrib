# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Mysql2
      module Patches
        # Module to prepend to Mysql2::Client for instrumentation
        module Statement
          def execute(*args, **kwargs)
            tracer.in_span(
              'execute',
              attributes: _otel_execute_attributes(args, kwargs),
              kind: :client
            ) do
              super
            end
          end

          private

          def _otel_execute_attributes(args, kwargs)
            if config[:db_statement] == :include
              { 'args' => args.to_s, 'kwargs' => kwargs.to_s }
            else
              {}
            end
          end

          def tracer
            Mysql2::Instrumentation.instance.tracer
          end

          def config
            Mysql2::Instrumentation.instance.config
          end
        end
      end
    end
  end
end

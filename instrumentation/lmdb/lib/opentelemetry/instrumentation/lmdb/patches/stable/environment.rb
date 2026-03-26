# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module LMDB
      module Patches
        module Stable
          # Module to prepend to LMDB::Environment for instrumentation
          module Environment
            def transaction(*args)
              attributes = {
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'TRANSACTION'
              }

              tracer.in_span('TRANSACTION', attributes: attributes) do
                super
              end
            end

            private

            def config
              LMDB::Instrumentation.instance.config
            end

            def tracer
              LMDB::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module LMDB
      module Patches
        module Dup
          # Module to prepend to LMDB::Environment for instrumentation
          module Environment
            def transaction(*args)
              attributes = {
                'db.system' => 'lmdb',
                'db.system.name' => 'lmdb',
                'db.operation.name' => 'TRANSACTION',
                'db.namespace' => path
              }
              attributes['peer.service'] = config[:peer_service] if config[:peer_service]

              tracer.in_span('TRANSACTION', attributes: attributes) do |span|
                super
              rescue StandardError => e
                set_error_attributes(span, e)
                raise
              end
            end

            private

            def set_error_attributes(span, error)
              span.set_attribute('error.type', error.class.name)
            end

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

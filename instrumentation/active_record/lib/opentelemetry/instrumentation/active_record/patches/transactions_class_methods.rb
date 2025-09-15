# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Base for instrumentation
        module TransactionsClassMethods
          def self.prepended(base)
            class << base
              prepend ClassMethods
            end
          end

          # Contains ActiveRecord::Transactions::ClassMethods to be patched
          module ClassMethods
            def transaction(*args, **kwargs, &block)
              attributes = { 'code.namespace' => name }
              if kwargs[:isolation]
                attributes['db.transaction_isolation'] = kwargs[:isolation].to_s
              end
              tracer.in_span('ActiveRecord.transaction', attributes: attributes) do
                super(*args, **kwargs, &block)
              end
            end

            private

            def tracer
              ActiveRecord::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end

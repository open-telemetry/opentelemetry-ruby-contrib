# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Shared exception matching for cases where specific exceptions are
        # intentionally re-raised after the span closes.
        module HandledExceptions
          DEFAULT_HANDLED_EXCEPTIONS = ['ActiveRecord::RecordInvalid'].freeze

          private

          def handled_exception?(exception)
            handled_exceptions.any? do |handled_exception|
              case handled_exception
              when Class
                exception.is_a?(handled_exception)
              when String, Symbol
                exception.class.ancestors.any? do |ancestor|
                  ancestor.name == handled_exception.to_s
                end
              else
                false
              end
            end
          end

          def handled_exceptions
            ActiveRecord::Instrumentation.instance.config.fetch(
              :handled_exceptions,
              DEFAULT_HANDLED_EXCEPTIONS
            )
          end
        end
      end
    end
  end
end
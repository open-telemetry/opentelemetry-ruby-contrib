# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Base for instrumentation
        # We patch these methods because they either raise, or call
        # the super implementation in persistence.rb
        # https://github.com/rails/rails/blob/v5.2.4.5/activerecord/lib/active_record/validations.rb#L42-L53
        # Contains the ActiveRecord::Validations methods to be patched
        module Validations
          def save(...)
            tracer.in_span("#{self.class}#save") do
              super
            end
          end

          def save!(...)
            record_invalid = nil
            result = tracer.in_span("#{self.class}#save!") do
              super
            rescue ::ActiveRecord::RecordInvalid => e
              record_invalid = e
            end
            raise record_invalid if record_invalid

            result
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

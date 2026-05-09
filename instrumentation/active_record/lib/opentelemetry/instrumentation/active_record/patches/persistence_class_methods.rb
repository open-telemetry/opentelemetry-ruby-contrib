# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveRecord
      module Patches
        # Module to prepend to ActiveRecord::Base for instrumentation
        module PersistenceClassMethods
          def self.prepended(base)
            class << base
              prepend ClassMethods
            end
          end

          # Contains ActiveRecord::Persistence::ClassMethods to be patched
          module ClassMethods
            def create(...)
              tracer.in_span("#{self}.create") do
                super
              end
            end

            def create!(...)
              record_invalid = nil
              result = tracer.in_span("#{self}.create!") do
                super
              rescue ::ActiveRecord::RecordInvalid => e
                record_invalid = e
              end
              raise record_invalid if record_invalid

              result
            end

            def update(...)
              tracer.in_span("#{self}.update") do
                super
              end
            end

            def destroy(...)
              tracer.in_span("#{self}.destroy") do
                super
              end
            end

            def delete(...)
              tracer.in_span("#{self}.delete") do
                super
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

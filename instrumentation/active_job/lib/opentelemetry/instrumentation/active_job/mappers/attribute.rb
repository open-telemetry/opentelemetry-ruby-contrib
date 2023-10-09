# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Mappers
        # Maps ActiveJob Attributes to Semantic Conventions
        class Attribute
          # Generates a set of attributes to add to a span using
          # general and messaging semantic conventions as well as
          # using `rails.active_job.*` namespace for custom attributes
          #
          # @param payload [Hash] of an ActiveSupport::Notifications payload
          # @return [Hash<String, Object>] of semantic attributes
          def call(payload)
            job = payload.fetch(:job)

            otel_attributes = {
              'code.namespace' => job.class.name,
              'messaging.system' => job.class.queue_adapter_name,
              'messaging.destination' => job.queue_name,
              'messaging.message.id' => job.job_id,
              'rails.active_job.execution.counter' => job.executions.to_i,
              'rails.active_job.provider_job_id' => job.provider_job_id.to_s,
              'rails.active_job.priority' => job.priority, # this can be problematic. Programs may use invalid attributes for priority.
              'rails.active_job.scheduled_at' => job.scheduled_at&.to_f
            }

            otel_attributes.compact!

            otel_attributes
          end
        end
      end
    end
  end
end

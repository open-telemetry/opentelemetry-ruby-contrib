# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveJob
      module Mappers
        # Maps ActiveJob Attributes to Semantic Conventions
        #
        # This follows the General and Messaging semantic conventions and uses `rails.active_job.*` namespace for custom attributes
        class Attribute
          def call(payload)
            job = payload.fetch(:job)

            otel_attributes = {
              'code.namespace' => job.class.name,
              'messaging.destination_kind' => 'queue',
              'messaging.system' => job.class.queue_adapter_name,
              'messaging.destination' => job.queue_name,
              'messaging.message_id' => job.job_id,
              'rails.active_job.execution.counter' => job.executions.to_i,
              'rails.active_job.provider_job_id' => job.provider_job_id.to_s,
              'rails.active_job.priority' => job.priority,
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

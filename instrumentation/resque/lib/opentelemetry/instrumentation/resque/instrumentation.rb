# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Resque
      # The Instrumentation class contains logic to detect and install the Resque instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch
        end

        present do
          defined?(::Resque)
        end

        ## Supported configuration keys for the install config hash:
        #
        # force_flush: controls if spans are forcibly flushed upon job completion
        #   - :ask_the_job (default) - if `Resque::Worker#fork_per_job?` is set,
        #     all completed spans will be synchronously flushed at the end of a
        #     job's execution
        #   - :always - all completed spans will be synchronously flushed at the
        #     end of a job's execution
        #   - :never - the job will not intervene with the processing of spans
        #
        # span_naming: when `:job_class`, the span names will be set to
        #   '<job class name> <operation>'. When `:queue`, the span names
        #   will be set to '<destination / queue name> <operation>'
        #
        # propagation_style: controls how the job's execution is traced and related
        #   to the trace where the job was enqueued. Can be one of:
        #   - :link (default) - the job will be executed in a separate trace. The
        #     initial span of the execution trace will be linked to the span that
        #     enqueued the job, via a Span Link.
        #   - :child - the job will be executed in the same logical trace, as a direct
        #     child of the span that enqueued the job.
        #   - :none - the job's execution will not be explicitly linked to the span that
        #     enqueued the job.

        option :force_flush,       default: :ask_the_job, validate: %I[ask_the_job always never]
        option :span_naming,       default: :queue,       validate: %I[job_class queue]
        option :propagation_style, default: :link,        validate: %i[link child none]

        private

        def patch
          ::Resque.prepend(Patches::ResqueModule)
          ::Resque::Job.prepend(Patches::ResqueJob)
        end

        def require_dependencies
          require_relative 'patches/resque_module'
          require_relative 'patches/resque_job'
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Instrumention for methods from Ruby's Logger class
        module Logger
          # TODO: Make sure OTel logs aren't instrumented
          # TODO: How to pass attributes?
          def format_message(severity, datetime, progname, msg)
            formatted_message = super(severity, datetime, progname, msg)
            return formatted_message if skip_instrumenting?

            OpenTelemetry.logger_provider.logger(
              'opentelemetry-instrumentation-logger',
              OpenTelemetry::Instrumentation::Logger::VERSION
            ).emit(
              severity_text: severity,
              severity_number: severity_number(severity),
              timestamp: datetime,
              body: formatted_message
            )

            formatted_message
          end

          private

          def instrumentation_config; end

          def skip_instrumenting?
            instance_variable_get(:@skip_instrumenting)
          end

          def severity_number(severity)
            ::Logger::Severity.const_get(severity)
          rescue NameError => e
            OpenTelemetry.handle_error(message: "Unable to coerce severity text #{severity} into severity_number. Setting severity_number to nil.", exception: e)
            nil
          end
        end
      end
    end
  end
end

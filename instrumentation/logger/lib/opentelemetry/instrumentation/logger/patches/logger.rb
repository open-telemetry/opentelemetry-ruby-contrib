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
          attr_writer :skip_otel_emit

          def format_message(severity, datetime, progname, msg)
            formatted_message = super
            return formatted_message if skip_otel_emit?

            OpenTelemetry.logger_provider.logger(
              name: OpenTelemetry::Instrumentation::Logger::NAME,
              version: OpenTelemetry::Instrumentation::Logger::VERSION
            ).on_emit(
              severity_text: severity,
              severity_number: severity_number(severity),
              timestamp: datetime,
              body: msg,
              context: OpenTelemetry::Context.current
            )
            formatted_message
          end

          private

          def skip_otel_emit?
            @skip_otel_emit || false
          end

          def severity_number(severity)
            case severity.downcase
            when 'debug'
              OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_DEBUG
            when 'info'
              OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_INFO
            when 'warn'
              OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_WARN
            when 'error'
              OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_ERROR
            when 'fatal'
              OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_FATAL
            else
              OpenTelemetry::Logs::SeverityNumber::SEVERITY_NUMBER_UNSPECIFIED
            end
          end
        end
      end
    end
  end
end

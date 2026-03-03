# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Logger
      module Patches
        # Instrumentation for methods from Ruby's Logger class
        module Logger
          IN_OTEL_EMIT_KEY = :in_otel_emit

          attr_writer :skip_otel_emit

          def format_message(severity, datetime, progname, msg)
            formatted_message = super

            emit_to_otel(severity, datetime, formatted_message)

            formatted_message
          end

          private

          def emit_to_otel(severity, datetime, body)
            return if skip_otel_emit? || Thread.current[IN_OTEL_EMIT_KEY]

            Thread.current[IN_OTEL_EMIT_KEY] = true
            begin
              OpenTelemetry.logger_provider.logger(
                name: OpenTelemetry::Instrumentation::Logger::NAME,
                version: OpenTelemetry::Instrumentation::Logger::VERSION
              ).on_emit(
                severity_text: severity,
                severity_number: severity_number(severity),
                timestamp: datetime,
                body: body,
                context: OpenTelemetry::Context.current
              )
            ensure
              Thread.current[IN_OTEL_EMIT_KEY] = false
            end
          end

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

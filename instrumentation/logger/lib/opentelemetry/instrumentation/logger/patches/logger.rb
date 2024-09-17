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
          attr_writer :skip_instrumenting

          def format_message(severity, datetime, progname, msg)
            formatted_message = super(severity, datetime, progname, msg)
            return formatted_message if skip_instrumenting?

            OpenTelemetry.logger_provider.logger(
              name: OpenTelemetry::Instrumentation::Logger::NAME,
              version: OpenTelemetry::Instrumentation::Logger::VERSION
            ).on_emit(
              severity_text: severity,
              severity_number: severity_number(severity),
              timestamp: datetime,
              body: msg, # New Relic uses formatted_message here. This also helps us with not recording progname, because it is included in the formatted message by default. Which seems more appropriate?
              context: OpenTelemetry::Context.current
            )
            formatted_message
          end

          private

          def skip_instrumenting?
            @skip_instrumenting || false
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

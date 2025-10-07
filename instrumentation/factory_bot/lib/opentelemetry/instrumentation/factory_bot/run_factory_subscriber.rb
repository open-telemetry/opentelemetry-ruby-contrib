# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module FactoryBot
      # Subscriber for factory_bot.run_factory ActiveSupport::Notifications
      class RunFactorySubscriber
        def tracer
          FactoryBot::Instrumentation.instance.tracer
        end

        def start(_name, _id, payload)
          factory_name = payload[:name]
          strategy_symbol = payload[:strategy].to_sym
          traits = payload[:traits] || []

          # Map user-facing strategy names to internal strategy names
          internal_strategy = case strategy_symbol
                              when :build_stubbed then 'stub'
                              else strategy_symbol.to_s
                              end

          span_name = "FactoryBot.#{strategy_symbol}(#{factory_name})"

          attrs = {
            'factory_bot.strategy' => internal_strategy,
            'factory_bot.factory_name' => factory_name.to_s
          }

          attrs['factory_bot.traits'] = traits.join(',') if traits.any?

          span = tracer.start_span(span_name, kind: :internal, attributes: attrs)
          token = OpenTelemetry::Context.attach(OpenTelemetry::Trace.context_with_span(span))

          payload.merge!(
            __opentelemetry_span: span,
            __opentelemetry_ctx_token: token
          )
        end

        def finish(_name, _id, payload)
          span = payload.delete(:__opentelemetry_span)
          token = payload.delete(:__opentelemetry_ctx_token)
          return unless span && token

          if (e = payload[:exception_object])
            span.record_exception(e)
            span.status = OpenTelemetry::Trace::Status.error("Unhandled exception of type: #{e.class}")
          end

          span.finish
          OpenTelemetry::Context.detach(token)
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module GraphQL
      module Tracers
        # GraphQLTracer contains the OpenTelemetry tracer implementation compatible with
        # the GraphQL tracer API
        class GraphQLTracer < ::GraphQL::Tracing::PlatformTracing
          TRACE_PHASE_TO_TYPE = {
            field: :enable_platform_field,
            authorized: :enable_platform_authorized,
            resolve_type: :enable_platform_resolve_type
          }.freeze

          self.platform_keys = {
            'lex' => 'graphql.lex',
            'parse' => 'graphql.parse',
            'validate' => 'graphql.validate',
            'analyze_query' => 'graphql.analyze_query',
            'analyze_multiplex' => 'graphql.analyze_multiplex',
            'execute_query' => 'graphql.execute_query',
            'execute_query_lazy' => 'graphql.execute_query_lazy',
            'execute_multiplex' => 'graphql.execute_multiplex'
          }

          def platform_trace(platform_key, key, data) # rubocop:disable Metrics/CyclomaticComplexity
            return yield if platform_key.nil?

            tracer.in_span(platform_key, attributes: attributes_for(key, data)) do |span|
              yield.tap do |response|
                errors = response[:errors]&.compact&.map { |e| e.to_h }&.to_json if key == 'validate'
                unless errors.nil?
                  span.add_event(
                    'graphql.validation.error',
                    attributes: {
                      'message' => errors
                    }
                  )
                end
              end
            end
          end

          def platform_field_key(type, field)
            return unless config[:enable_platform_field]

            "#{type.graphql_name}.#{field.graphql_name}"
          end

          def platform_authorized_key(type)
            return unless config[:enable_platform_authorized]

            "#{type.graphql_name}.authorized"
          end

          def platform_resolve_type_key(type)
            return unless config[:enable_platform_resolve_type]

            "#{type.graphql_name}.resolve_type"
          end

          private

          def tracer
            GraphQL::Instrumentation.instance.tracer
          end

          def config
            GraphQL::Instrumentation.instance.config
          end

          def attributes_for(key, data)
            attributes = {}
            case key
            when 'execute_query'
              attributes['graphql.operation.name'] = data[:query].selected_operation_name if data[:query].selected_operation_name
              attributes['graphql.operation.type'] = data[:query].selected_operation.operation_type
              attributes['graphql.document'] = data[:query].query_string
            end
            attributes
          end

          def cached_platform_key(ctx, key, trace_phase = nil)
            cache = ctx.namespace(self.class)[:platform_key_cache] ||= {}
            cache.fetch(key) do
              cache[key] = if trace_phase.nil?
                             # Backwards compatibility for graphql-ruby < 1.13.13 and >= 2 < 2.0.9
                             # Relates to https://github.com/rmosolgo/graphql-ruby/pull/4077
                             yield
                           else
                             ns = ctx.namespace(:opentelemetry)
                             if ns.empty?
                               # Execution context not provided so no request specific config to check
                               yield
                             else
                               config_key = TRACE_PHASE_TO_TYPE.fetch(trace_phase)
                               yield if ns.fetch(config_key, true)
                             end
                           end
            end
          end
        end
      end
    end
  end
end

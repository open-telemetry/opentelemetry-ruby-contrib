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

          def platform_trace(platform_key, key, data)
            return yield if platform_key.nil?

            tracer.in_span(platform_key, attributes: attributes_for(key, data)) do |span|
              yield.tap do |response|
                next unless key == 'validate'

                errors = response[:errors]&.compact&.map(&:to_h) || []

                unless errors.empty?
                  span.add_event(
                    'graphql.validation.error',
                    attributes: {
                      'exception.message' => errors.to_json
                    }
                  )
                end
              end
            end
          end

          def platform_field_key(type, field)
            return unless config[:enable_platform_field]

            if config[:legacy_platform_span_names]
              "#{type.graphql_name}.#{field.graphql_name}"
            else
              'graphql.execute_field'
            end
          end

          def platform_authorized_key(type)
            return unless config[:enable_platform_authorized]

            if config[:legacy_platform_span_names]
              "#{type.graphql_name}.authorized"
            else
              'graphql.authorized'
            end
          end

          def platform_resolve_type_key(type)
            return unless config[:enable_platform_resolve_type]

            if config[:legacy_platform_span_names]
              "#{type.graphql_name}.resolve_type"
            else
              'graphql.resolve_type'
            end
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
            when 'execute_field', 'execute_field_lazy'
              attributes['graphql.field.parent'] = data[:owner]&.graphql_name # owner is the concrete type, not interface
              attributes['graphql.field.name'] = data[:field]&.graphql_name
              attributes['graphql.lazy'] = key == 'execute_field_lazy'
            when 'authorized', 'authorized_lazy'
              attributes['graphql.type.name'] = data[:type]&.graphql_name
              attributes['graphql.lazy'] = key == 'authorized_lazy'
            when 'resolve_type', 'resolve_type_lazy'
              attributes['graphql.type.name'] = data[:type]&.graphql_name
              attributes['graphql.lazy'] = key == 'resolve_type_lazy'
            when 'execute_query'
              attributes['graphql.operation.name'] = data[:query].selected_operation_name if data[:query].selected_operation_name
              attributes['graphql.operation.type'] = data[:query].selected_operation.operation_type
              attributes['graphql.document'] = data[:query].query_string
            end
            attributes
          end
        end
      end
    end
  end
end

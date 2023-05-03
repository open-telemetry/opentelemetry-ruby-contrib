# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'

module OpenTelemetry
  module Instrumentation
    module GraphQL
      module Tracers
        # GraphQLTrace contains the OpenTelemetry tracer implementation compatible with
        # the new GraphQL tracing API (>= 2.0.18)
        module GraphQLTrace # rubocop:disable Metrics/ModuleLength
          def self.platform_keys
            {
              'lex' => 'graphql.lex',
              'parse' => 'graphql.parse',
              'validate' => 'graphql.validate',
              'analyze_query' => 'graphql.analyze_query',
              'analyze_multiplex' => 'graphql.analyze_multiplex',
              'execute_query' => 'graphql.execute_query',
              'execute_query_lazy' => 'graphql.execute_query_lazy',
              'execute_multiplex' => 'graphql.execute_multiplex'
            }
          end

          platform_keys.each do |trace_method, platform_key|
            module_eval(
              #  def lex(**data, &block)
              #    attributes = attributes_for("lex", data)
              #
              #    tracer.in_span("graphql.lex", attributes: attributes) do |span|
              #      super.tap do |response|
              #        errors = response[:errors]&.compact&.map(&:to_h)&.to_json if "lex" == 'validate'
              #        unless errors.nil?
              #          span.add_event(
              #            'graphql.validation.error',
              #            attributes: {
              #              'message' => errors
              #            }
              #          )
              #        end
              #      end
              #    end
              #  end
              <<-RUBY, __FILE__, __LINE__ + 1
                def #{trace_method}(**data, &block)
                  attributes = attributes_for("#{trace_method}", data)

                  tracer.in_span("#{platform_key}", attributes: attributes) do |span|
                    super.tap do |response|
                      errors = response[:errors]&.compact&.map(&:to_h)&.to_json if "#{trace_method}" == 'validate'
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
              RUBY
            )
          end

          %i[execute_field execute_field_lazy].each do |trace_method|
            module_eval(
              # def platform_execute_field(platform_key, data, &block)
              #   instrument_execution(platform_key, "execute_field", data, &block)
              # end
              <<-RUBY, __FILE__, __LINE__ + 1
                def platform_#{trace_method}(platform_key, data, &block)
                  instrument_execution(platform_key, "#{trace_method}", data, &block)
                end
              RUBY
            )
          end

          %i[authorized authorized_lazy].each do |trace_method|
            module_eval(
              #  def authorized(type:, query:, **_rest)
              #    platform_key = @platform_authorized_key_cache[type]
              #    return super unless platform_key

              #    instrument_execution(platform_key, "authorized", { query: query, type: type }) do
              #      super
              #    end
              #  end
              <<-RUBY, __FILE__, __LINE__ + 1
                def #{trace_method}(type:, query:, **_rest)
                  platform_key = @platform_authorized_key_cache[type]
                  return super unless platform_key

                  instrument_execution(platform_key, "#{trace_method}", { query: query, type: type }) do
                    super
                  end
                end
              RUBY
            )
          end

          %i[resolve_type resolve_type_lazy].each do |trace_method|
            module_eval(
              # def resolve_type(type:, query:, **_rest)
              #   platform_key = @platform_resolve_type_key_cache[type]
              #   instrument_execution(platform_key, "resolve_type", { query: query, type: type }) do
              #     super
              #   end
              # end
              <<-RUBY, __FILE__, __LINE__ + 1
                def #{trace_method}(type:, query:, **_rest)
                  platform_key = @platform_resolve_type_key_cache[type]
                  instrument_execution(platform_key, "#{trace_method}", { query: query, type: type }) do
                    super
                  end
                end
              RUBY
            )
          end

          include ::GraphQL::Tracing::PlatformTrace

          def platform_field_key(field)
            return unless config[:enable_platform_field]

            if config[:legacy_platform_span_names]
              field.path
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

          def instrument_execution(platform_key, key, data, &block)
            attributes = attributes_for(key, data)
            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          def tracer
            GraphQL::Instrumentation.instance.tracer
          end

          def config
            GraphQL::Instrumentation.instance.config
          end

          def attributes_for(key, data) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
            attributes = {}
            case key
            when 'execute_field', 'execute_field_lazy'
              attributes['graphql.field.parent'] = data[:field]&.owner&.graphql_name
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

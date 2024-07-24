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
          def initialize(trace_scalars: false, **_options)
            @trace_scalars = trace_scalars
            @_otel_field_key_cache = Hash.new { |h, k| h[k] = _otel_field_key(k) }
            @_otel_field_key_cache.compare_by_identity
            @_otel_authorized_key_cache = Hash.new { |h, k| h[k] = _otel_authorized_key(k) }
            @_otel_authorized_key_cache.compare_by_identity
            @_otel_resolve_type_key_cache = Hash.new { |h, k| h[k] = _otel_resolve_type_key(k) }
            @_otel_resolve_type_key_cache.compare_by_identity

            @_otel_type_attrs_cache = Hash.new do |h, type|
              h[type] = {
                'graphql.type.name' => type.graphql_name,
                'graphql.lazy' => false
              }.freeze
            end
            @_otel_type_attrs_cache.compare_by_identity

            @_otel_lazy_type_attrs_cache = Hash.new do |h, type|
              h[type] = {
                'graphql.type.name' => type.graphql_name,
                'graphql.lazy' => true
              }.freeze
            end
            @_otel_lazy_type_attrs_cache.compare_by_identity

            @_otel_field_attrs_cache = Hash.new do |h, field|
              h[field] = {
                'graphql.field.parent' => field.owner&.graphql_name,
                'graphql.field.name' => field.graphql_name,
                'graphql.lazy' => false
              }.freeze
            end
            @_otel_field_attrs_cache.compare_by_identity

            @_otel_lazy_field_attrs_cache = Hash.new do |h, field|
              h[field] = {
                'graphql.field.parent' => field.owner&.graphql_name,
                'graphql.field.name' => field.graphql_name,
                'graphql.lazy' => true
              }.freeze
            end
            @_otel_lazy_field_attrs_cache.compare_by_identity

            super
          end

          def execute_multiplex(multiplex:, &block)
            tracer.in_span('graphql.execute_multiplex', &block)
          end

          def lex(query_string:, &block)
            tracer.in_span('graphql.lex', &block)
          end

          def parse(query_string:, &block)
            tracer.in_span('graphql.parse', &block)
          end

          def validate(query:, validate:, &block)
            tracer.in_span('graphql.validate') do |span|
              super.tap do |response|
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

          def analyze_multiplex(multiplex:, &block)
            tracer.in_span('graphql.analyze_multiplex', &block)
          end

          def analyze_query(query:, &block)
            tracer.in_span('graphql.analyze_query', &block)
          end

          def execute_query(query:, &block)
            attributes = {}
            operation_type = query.selected_operation.operation_type
            operation_name = query.selected_operation_name

            attributes['graphql.operation.name'] = operation_name if operation_name
            attributes['graphql.operation.type'] = operation_type
            attributes['graphql.document'] = query.query_string

            span_name = operation_name ? "#{operation_type} #{operation_name}" : operation_type
            tracer.in_span(span_name, attributes: attributes, &block)
          end

          def execute_query_lazy(query:, multiplex:, &block)
            tracer.in_span('graphql.execute_query_lazy', &block)
          end

          def execute_field(field:, query:, ast_node:, arguments:, object:, &block)
            platform_key = _otel_execute_field_key(field: field)
            return super(field: field, query: query, ast_node: ast_node, object: object, arguments: arguments, &block) unless platform_key

            attributes = @_otel_field_attrs_cache[field]

            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          def execute_field_lazy(field:, query:, ast_node:, arguments:, object:, &block)
            platform_key = _otel_execute_field_key(field: field)
            return super(field: field, query: query, ast_node: ast_node, object: object, arguments: arguments, &block) unless platform_key

            attributes = @_otel_lazy_field_attrs_cache[field]

            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          def authorized(query:, type:, object:, &block)
            platform_key = @_otel_authorized_key_cache[type]
            return super unless platform_key

            attributes = @_otel_type_attrs_cache[type]

            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          def authorized_lazy(query:, type:, object:, &block)
            platform_key = @_otel_authorized_key_cache[type]
            return super unless platform_key

            attributes = @_otel_lazy_type_attrs_cache[type]
            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          def resolve_type(query:, type:, object:, &block)
            platform_key = @_otel_resolve_type_key_cache[type]
            attributes = @_otel_type_attrs_cache[type]
            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          def resolve_type_lazy(query:, type:, object:, &block)
            platform_key = @_otel_resolve_type_key_cache[type]
            attributes = @_otel_lazy_type_attrs_cache[type]
            tracer.in_span(platform_key, attributes: attributes, &block)
          end

          private

          def _otel_execute_field_key(field:, &block)
            trace_field = trace_field?(field)
            platform_key = @_otel_field_key_cache[field] if trace_field
            platform_key if platform_key && trace_field
          end

          def trace_field?(field)
            return_type = field.type.unwrap

            if return_type.kind.scalar? || return_type.kind.enum?
              (field.trace.nil? && @trace_scalars) || field.trace
            else
              true
            end
          end

          def _otel_field_key(field)
            return unless config[:enable_platform_field]

            if config[:legacy_platform_span_names]
              field.path
            else
              'graphql.execute_field'
            end
          end

          def _otel_authorized_key(type)
            return unless config[:enable_platform_authorized]

            if config[:legacy_platform_span_names]
              "#{type.graphql_name}.authorized"
            else
              'graphql.authorized'
            end
          end

          def _otel_resolve_type_key(type)
            return unless config[:enable_platform_resolve_type]

            if config[:legacy_platform_span_names]
              "#{type.graphql_name}.resolve_type"
            else
              'graphql.resolve_type'
            end
          end

          def tracer
            GraphQL::Instrumentation.instance.tracer
          end

          def config
            GraphQL::Instrumentation.instance.config
          end
        end
      end
    end
  end
end

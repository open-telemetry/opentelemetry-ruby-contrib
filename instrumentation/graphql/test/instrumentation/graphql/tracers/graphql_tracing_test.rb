# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/graphql'

describe 'GraphQL Tracing' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:config) { {} }

  let(:query_string) do
    <<-GRAPHQL
      query($id: Int!){
        simpleField
        resolvedField(id: $id) {
          originalValue
          uppercasedValue
        }
      }
    GRAPHQL
  end

  before do
    # Reset various instance variables to clear state between tests
    [GraphQL::Schema, SomeOtherGraphQLAppSchema, SomeGraphQLAppSchema].each(&:_reset_tracer_for_testing)

    instrumentation.instance_variable_set(:@installed, false)
    config[:legacy_tracing] = instrumentation.legacy_tracing_requirement_satisfied?
    instrumentation.install(config)

    exporter.reset
  end

  describe '#platform_trace' do
    it 'traces platform keys' do
      result = SomeGraphQLAppSchema.execute(query_string, variables: { id: 1 })

      _(spans.size).must_equal(8)

      _(result.to_h['data']).must_equal('simpleField' => 'Hello.', 'resolvedField' => { 'originalValue' => 'testing=1', 'uppercasedValue' => 'TESTING=1' })
    end

    it 'includes operation attributes for execute_query' do
      expected_attributes = {
        'graphql.operation.name' => 'SimpleQuery',
        'graphql.operation.type' => 'query',
        'graphql.document' => 'query SimpleQuery{ simpleField }'
      }

      SomeGraphQLAppSchema.execute('query SimpleQuery{ simpleField }')

      span = spans.find { |s| s.name == 'graphql.execute_query' }
      _(span).wont_be_nil
      _(span.attributes.to_h).must_equal(expected_attributes)
    end

    it 'omits nil attributes for execute_query' do
      expected_attributes = {
        'graphql.operation.type' => 'query',
        'graphql.document' => '{ simpleField }'
      }

      SomeGraphQLAppSchema.execute('{ simpleField }')

      span = spans.find { |s| s.name == 'graphql.execute_query' }
      _(span).wont_be_nil
      _(span.attributes.to_h).must_equal(expected_attributes)
    end

    describe 'when a set of schemas is provided' do
      let(:config) { { schemas: [SomeOtherGraphQLAppSchema] } }

      after do
        # Reset various instance variables to clear state between tests
        SomeOtherGraphQLAppSchema.instance_variable_set(:@own_tracers, [])
        SomeOtherGraphQLAppSchema.instance_variable_set(:@own_plugins, SomeOtherGraphQLAppSchema.plugins[0..1])
      end

      it 'traces the provided schemas' do
        SomeOtherGraphQLAppSchema.execute('query SimpleQuery{ __typename }')

        _(spans.size).must_equal(8)
      end

      it 'does not trace all schemas' do
        SomeGraphQLAppSchema.execute('query SimpleQuery{ __typename }')

        _(spans).must_be(:empty?)
      end
    end

    describe 'when platform_field is enabled with legacy naming' do
      let(:config) { { enable_platform_field: true, legacy_platform_span_names: true } }

      it 'traces execute_field' do
        SomeGraphQLAppSchema.execute(query_string, variables: { id: 1 })

        span = spans.find { |s| s.name == 'Query.resolvedField' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_field is enabled' do
      let(:config) { { enable_platform_field: true } }

      it 'traces execute_field' do
        SomeGraphQLAppSchema.execute(query_string, variables: { id: 1 })

        span = spans.find do |s|
          s.name == 'graphql.execute_field' &&
            s.attributes['graphql.field.parent'] == 'Query' &&
            s.attributes['graphql.field.name'] == 'resolvedField'
        end
        _(span).wont_be_nil
      end

      it 'includes attributes using platform types' do
        skip if uses_platform_interfaces?
        expected_attributes = {
          'graphql.field.parent' => 'Car', # type name, not interface
          'graphql.field.name' => 'model',
          'graphql.lazy' => false
        }

        SomeGraphQLAppSchema.execute('{ vehicle { model } }')

        span = spans.find { |s| s.name == 'graphql.execute_field' && s.attributes['graphql.field.name'] == 'model' }
        _(span).wont_be_nil
        _(span.attributes.to_h).must_equal(expected_attributes)
      end

      it 'includes attributes using platform interfaces' do
        skip unless uses_platform_interfaces?
        expected_attributes = {
          'graphql.field.parent' => 'Vehicle', # interface name, not type
          'graphql.field.name' => 'model',
          'graphql.lazy' => false
        }

        SomeGraphQLAppSchema.execute('{ vehicle { model } }')

        span = spans.find { |s| s.name == 'graphql.execute_field' && s.attributes['graphql.field.name'] == 'model' }
        _(span).wont_be_nil
        _(span.attributes.to_h).must_equal(expected_attributes)
      end
    end

    describe 'when platform_authorized is enabled with legacy naming' do
      let(:config) { { enable_platform_authorized: true, legacy_platform_span_names: true } }

      it 'traces .authorized' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute(query_string, variables: { id: 1 })

        span = spans.find { |s| s.name == 'Query.authorized' }
        _(span).wont_be_nil

        span = spans.find { |s| s.name == 'SlightlyComplex.authorized' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_authorized is enabled' do
      let(:config) { { enable_platform_authorized: true, legacy_platform_span_names: false } }

      it 'traces .authorized' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute(query_string, variables: { id: 1 })

        span = spans.find do |s|
          s.name == 'graphql.authorized' &&
            s.attributes['graphql.type.name'] == 'Query'
        end
        _(span).wont_be_nil

        span = spans.find do |s|
          s.name == 'graphql.authorized' &&
            s.attributes['graphql.type.name'] == 'SlightlyComplex'
        end
        _(span).wont_be_nil
      end

      it 'includes attributes' do
        skip unless supports_authorized_and_resolved_types?
        expected_attributes = {
          'graphql.type.name' => 'OtherQuery',
          'graphql.lazy' => false
        }

        SomeOtherGraphQLAppSchema.execute('{ simpleField }')

        span = spans.find { |s| s.name == 'graphql.authorized' }
        _(span).wont_be_nil
        _(span.attributes.to_h).must_equal(expected_attributes)
      end
    end

    describe 'when platform_resolve_type is enabled with legacy naming' do
      let(:config) { { enable_platform_resolve_type: true, legacy_platform_span_names: true } }

      it 'traces .resolve_type' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute('{ vehicle { __typename } }')

        span = spans.find { |s| s.name == 'Vehicle.resolve_type' }
        _(span).wont_be_nil
      end
    end

    describe 'when platform_resolve_type is enabled' do
      let(:config) { { enable_platform_resolve_type: true } }

      it 'traces .resolve_type' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute('{ vehicle { __typename } }')

        span = spans.find { |s| s.name == 'graphql.resolve_type' && s.attributes['graphql.type.name'] == 'Vehicle' }
        _(span).wont_be_nil
      end

      it 'traces .resolve_type_lazy' do
        skip unless supports_authorized_and_resolved_types?
        SomeGraphQLAppSchema.execute('{ vehicle { __typename } }', context: { lazy_type_resolve: true })

        span = spans.find do |s|
          s.name == 'graphql.resolve_type' &&
            s.attributes['graphql.type.name'] == 'Vehicle' &&
            s.attributes['graphql.lazy'] == true
        end

        _(span).wont_be_nil
      end

      it 'includes attributes' do
        skip unless supports_authorized_and_resolved_types?
        expected_attributes = {
          'graphql.type.name' => 'Vehicle',
          'graphql.lazy' => false
        }

        SomeGraphQLAppSchema.execute('{ vehicle { __typename } }')

        span = spans.find { |s| s.name == 'graphql.resolve_type' }
        _(span).wont_be_nil
        _(span.attributes.to_h).must_equal(expected_attributes)
      end
    end

    it 'traces validate with events' do
      SomeGraphQLAppSchema.execute(
        <<-GRAPHQL
          {
            nonExistentField
          }
        GRAPHQL
      )
      span = spans.find { |s| s.name == 'graphql.validate' }
      event = span.events.find { |e| e.name == 'graphql.validation.error' }
      # rubocop:disable Layout/LineLength
      _(event.attributes['message']).must_equal(
        "[{\"message\":\"Field 'nonExistentField' doesn't exist on type 'Query'\",\"locations\":[{\"line\":2,\"column\":13}],\"path\":[\"query\",\"nonExistentField\"],\"extensions\":{\"code\":\"undefinedField\",\"typeName\":\"Query\",\"fieldName\":\"nonExistentField\"}}]"
      )
      # rubocop:enable Layout/LineLength
    end
  end

  private

  # These fields are only supported as of version 1.10.0
  # https://github.com/rmosolgo/graphql-ruby/blob/v1.10.0/CHANGELOG.md#new-features-1
  def supports_authorized_and_resolved_types?
    Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
  end

  module Old
    Truck = Struct.new(:price, :model)
  end

  module Vehicle
    include GraphQL::Schema::Interface

    field :model, String, null: true, trace: true # Allow for this scalar to be traced
  end

  class Car < GraphQL::Schema::Object
    implements Vehicle

    field :price, Integer, null: true
  end

  class SlightlyComplexType < GraphQL::Schema::Object
    field :uppercased_value, String, null: false
    field :original_value, String, null: false

    def uppercased_value
      object.original_value.upcase
    end
  end

  class SimpleResolver < GraphQL::Schema::Resolver
    type SlightlyComplexType, null: false

    argument :id, Integer, required: true

    def resolve(id:)
      Struct.new(:original_value).new("testing=#{id}")
    end
  end

  class QueryType < GraphQL::Schema::Object
    field :simple_field, String, null: false
    field :resolved_field, resolver: SimpleResolver

    # Required for testing resolve_type
    field :vehicle, Vehicle, null: true

    def vehicle
      Old::Truck.new(50, 'Model T')
    end

    def simple_field
      'Hello.'
    end
  end

  LazyBox = Struct.new(:value)

  class OtherQueryType < GraphQL::Schema::Object
    field :simple_field, String, null: false
    def simple_field
      'Hello.'
    end
  end

  class SomeOtherGraphQLAppSchema < GraphQL::Schema
    query(::OtherQueryType)
  end

  class SomeGraphQLAppSchema < GraphQL::Schema
    query(::QueryType)
    orphan_types Car
    lazy_resolve(LazyBox, :value)

    def self.resolve_type(_type, _obj, ctx)
      if ctx[:lazy_type_resolve]
        LazyBox.new(Car)
      else
        Car
      end
    end
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.10.0')
    [SomeOtherGraphQLAppSchema, SomeGraphQLAppSchema].each do |schema|
      schema.class_eval do
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end
  end

  # https://github.com/rmosolgo/graphql-ruby/issues/4292 changes the behavior of the platform tracer to use interface keys instead of the concrete types
  def uses_platform_interfaces?
    Gem::Requirement.new('>= 2.0.19').satisfied_by?(gem_version)
  end

  def gem_version
    Gem::Version.new(GraphQL::VERSION)
  end
end

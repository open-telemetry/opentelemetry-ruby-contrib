# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'minitest/autorun'
require 'webmock/minitest'

# global opentelemetry-sdk setup:
EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.add_span_processor span_processor
end

# Hack that allows us to reset the internal state of the tracer to test installation
module SchemaTestPatches
  # Reseting @graphql_definition is needed for tests running against version `1.9.x`
  # Other variables are used by ~> 2.0.19
  def _reset_tracer_for_testing
    %w[own_tracers trace_modes trace_class tracers graphql_definition own_trace_modes].each do |name|
      ivar_name = "@#{name}"
      remove_instance_variable(ivar_name) if instance_variable_defined?(ivar_name)
    end
  end
end

GraphQL::Schema.extend(SchemaTestPatches)

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

class SomeOtherGraphQLAppSchema < GraphQL::Schema
  query(::OtherQueryType)
end

# These fields are only supported as of version 1.10.0
# https://github.com/rmosolgo/graphql-ruby/blob/v1.10.0/CHANGELOG.md#new-features-1
def supports_authorized_and_resolved_types?
  Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
end

# https://github.com/rmosolgo/graphql-ruby/issues/4292 changes the behavior of the platform tracer to use interface keys instead of the concrete types
def uses_platform_interfaces?
  Gem::Requirement.new('>= 2.0.19').satisfied_by?(gem_version)
end

def gem_version
  Gem::Version.new(GraphQL::VERSION)
end

# When tracing, is the parser expected to call `lex` before `parse`
def trace_lex_supported?
  return @trace_lex_supported if defined?(@trace_lex_supported)

  # In GraphQL 2.2, the default parser was changed such that `lex` is no longer called
  @trace_lex_supported = Gem::Requirement.new('< 2.2').satisfied_by?(Gem::Version.new(GraphQL::VERSION)) ||
                         (defined?(GraphQL::CParser) == 'constant')
end

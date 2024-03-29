# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-test-helpers'
require_relative '../../../lib/opentelemetry/instrumentation/graphql'

describe OpenTelemetry::Instrumentation::GraphQL do
  let(:instrumentation) { OpenTelemetry::Instrumentation::GraphQL::Instrumentation.instance }

  before do
    # Remove added tracers
    GraphQL::Schema._reset_tracer_for_testing
    instrumentation.instance_variable_set(:@installed, false)
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::GraphQL'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    describe 'when legacy_tracing is disabled' do
      let(:config) { { schemas: [SomeGraphQLAppSchema], legacy_tracing: false } }

      it 'installs the GraphQLTrace instrumentation using the latest api' do
        skip unless instrumentation.supports_new_tracer?

        expected_tracer = OpenTelemetry::Instrumentation::GraphQL::Tracers::GraphQLTrace
        instrumentation.install(config)
        _(SomeGraphQLAppSchema.trace_class.ancestors).must_include(expected_tracer)
      end

      it 'does not install on incompatible versions of GraphQL' do
        skip if instrumentation.supports_new_tracer?

        instrumentation.install(config)
        _(instrumentation.installed?).must_equal(false)
      end

      describe 'when a user supplies an invalid schema' do
        let(:config) { { schemas: [Old::Truck], legacy_tracing: false } }

        it 'fails gracefully and logs the error' do
          skip unless instrumentation.supports_new_tracer?

          OpenTelemetry::TestHelpers.with_test_logger do |log|
            instrumentation.install(config)
            _(log.string).must_match(
              /undefined method `trace_with'.*Old::Truck/
            )
          end
        end
      end
    end

    describe 'when legacy_tracing is enabled' do
      let(:config) { { schemas: [SomeGraphQLAppSchema], legacy_tracing: true } }

      it 'installs the GraphQLTracer instrumentation using legacy api' do
        skip unless instrumentation.supports_legacy_tracer?

        expected_tracer = OpenTelemetry::Instrumentation::GraphQL::Tracers::GraphQLTracer
        instrumentation.install(config)
        _(instrumentation.installed?).must_equal(true)
        _(SomeGraphQLAppSchema.tracers[0].class).must_equal(expected_tracer)
      end

      it 'does not install instrumentation on gem versions that do not support it' do
        skip if instrumentation.supports_legacy_tracer?

        instrumentation.install(config)
        _(instrumentation.installed?).must_equal(false)
      end

      describe 'when a user supplies an invalid schema' do
        let(:config) { { schemas: [Old::Truck], legacy_tracing: true } }

        it 'fails gracefully and logs the error' do
          skip unless instrumentation.supports_legacy_tracer?

          OpenTelemetry::TestHelpers.with_test_logger do |log|
            instrumentation.install(config)

            _(log.string).must_match(
              /undefined method `use'.*Old::Truck/
            )
          end
        end
      end
    end
  end
end

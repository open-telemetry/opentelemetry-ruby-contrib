# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

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
    describe 'when a user supplies an invalid schema' do
      let(:config) { { schemas: [Old::Truck], legacy_tracing: !instrumentation.use_new_tracing_api? } }

      it 'fails gracefully and logs the error' do
        mock_logger = Minitest::Mock.new
        mock_logger.expect(:error, nil, [String])
        OpenTelemetry.stub :logger, mock_logger do
          instrumentation.install(config)
        end
        mock_logger.verify
      end
    end
  end
end

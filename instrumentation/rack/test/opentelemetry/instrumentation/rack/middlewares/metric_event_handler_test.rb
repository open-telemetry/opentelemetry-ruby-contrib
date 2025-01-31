# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../test_helper'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/middlewares/metrics_event_handler'

# test command:
# be appraisal rack-latest ruby test/opentelemetry/instrumentation/rack/middlewares/metric_event_handler_test.rb
describe 'OpenTelemetry::Instrumentation::Rack::Middlewares::MetricsEventHandler' do
  include Rack::Test::Methods

  let(:instrumentation_module) { OpenTelemetry::Instrumentation::Rack }
  let(:instrumentation_class) { instrumentation_module::Instrumentation }
  let(:instrumentation) { instrumentation_class.instance }
  let(:send_metrics) { true }
  let(:config) do
    {
      send_metrics: send_metrics,
      use_rack_events: true
    }
  end

  let(:handler) do
    OpenTelemetry::Instrumentation::Rack::Middlewares::MetricsEventHandler.new
  end

  let(:exporter) { METRICS_EXPORTER }

  let(:last_snapshot) do
    exporter.pull
    exporter.metric_snapshots
  end

  let(:after_close) { nil }
  let(:response_body) { Rack::BodyProxy.new(['Hello World']) { after_close&.call } }
  let(:service) do
    ->(_arg) { [200, { 'Content-Type' => 'text/plain' }, response_body] }
  end

  let(:app) do
    Rack::Builder.new.tap do |builder|
      builder.use Rack::Events, [handler]
      builder.run service
    end
  end

  let(:uri) { '/' }
  let(:headers) { {} }

  before do
    exporter.reset
    instrumentation.instance_variable_set(:@installed, false)
    # TODO: fix this so we don't have to force metrics to be enabled
    instrumentation.instance_variable_set(:@metrics_enabled, true)
    instrumentation.install(config)
  end

  describe '#call' do
    before do
      get uri, {}, headers
    end

    it 'records a metric' do
      metric = last_snapshot[0][0]
      assert_instance_of OpenTelemetry::SDK::Metrics::State::MetricData, metric
      assert_equal metric.name, 'http.server.request.duration'
      assert_equal metric.description, 'Duration of HTTP server requests.'
      assert_equal metric.unit, 's'
      assert_equal metric.instrument_kind, :histogram
      assert_equal metric.data_points[0].attributes, { 'http.method' => 'GET', 'http.host' => 'example.org', 'http.scheme' => 'http', 'http.route' => '/', 'http.response.status.code' => 200 }
      # assert_equal metric.data_points[0].sum?, expected # to check the duration
    end

    # it 'records an error class if raised' {}
    # it 'creates the right histogram' {}
    # it 'assigns the right attributes' {}
    # it 'does not record a metric if send_metrics is false' {}
    # # do we need a totally separate testing environment for metrics so that the
    # # traces tests do not run with the metrics sdk and api enabled?
    # it 'rescues errors raised by OTel on_start' {}
    # it 'rescues errors raised by OTel on_error' {}
    # it 'rescues errors raised by OTel on_finish' {}
    # it 'preserves the :start_time in the rack environment?' {}
    # it 'includes a query string where present' {}
    # it 'does not include the question mark if the query string is blank' {}
    # it 'has a valid duration recorded for the value' {}
    # it 'records data points for multiple requests' {}
    # it 'creates the instrument only once' {}
  end
end

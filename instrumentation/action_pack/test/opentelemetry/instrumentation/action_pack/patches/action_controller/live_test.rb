# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::ActionPack::Patches::ActionController::Live do
  include Rack::Test::Methods

  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }
  let(:rails_app) { DEFAULT_RAILS_APP }
  let(:config) { {} }

  # Clear captured spans
  before do
    OpenTelemetry::Instrumentation::ActionPack::Handlers.unsubscribe

    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)

    exporter.reset
  end

  it 'creates a child span for the new thread' do
    get '/stream'

    parent_span = spans[-2]

    _(last_response.ok?).must_equal true
    _(span.name).must_equal 'ExampleLiveController#stream stream'
    _(span.kind).must_equal :internal
    _(span.status.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::ActionPack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::ActionPack::VERSION

    _(span.attributes['code.namespace']).must_equal 'ExampleLiveController'
    _(span.attributes['code.function']).must_equal 'stream'

    _(span.parent_span_id).must_equal parent_span.span_id
  end

  def app
    rails_app
  end
end

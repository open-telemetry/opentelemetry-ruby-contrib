# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/action_pack'
require_relative '../../../../lib/opentelemetry/instrumentation/action_pack/action_controller_subscriber'

describe OpenTelemetry::Instrumentation::ActionPack::ActionControllerSubscriber do
  include Rack::Test::Methods

  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { exporter.finished_spans.last }
  let(:rails_app) { DEFAULT_RAILS_APP }

  # Clear captured spans
  before { exporter.reset }

  it 'sets the view runtime' do
    get '/ok'

    _(last_response.body).must_equal 'actually ok'
    _(last_response.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    _(span.attributes['rails.view.duration']).must_be :>=, 0
  end

  it 'sets the db runtime' do
    get '/query'

    _(last_response.body).must_equal 'make query'
    _(last_response.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    _(span.attributes['rails.db.duration']).must_be :>=, 0
  end

  it 'sets common active support notification attributes' do
    get '/ok'

    _(last_response.body).must_equal 'actually ok'
    _(last_response.ok?).must_equal true

    _(span.instrumentation_library.name).must_equal 'OpenTelemetry::Instrumentation::Rack'
    _(span.instrumentation_library.version).must_equal OpenTelemetry::Instrumentation::Rack::VERSION

    below_rails('6') do
      _(span.attributes['process.runtime.ruby.allocations.count']).must_be_nil
      _(span.attributes['rails.cpu.duration']).must_be_nil
    end

    equal_or_above_rails('6') do
      _(span.attributes['process.runtime.ruby.allocations.count']).must_be :>=, 0
      _(span.attributes['rails.cpu.duration']).must_be :>=, 0
    end
  end

  def app
    rails_app
  end
end

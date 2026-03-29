# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/rack/middlewares/old/event_handler'

describe 'OpenTelemetry::Instrumentation::Rack::Middlewares::EventHandler::ResiliencyTest' do
  let(:handler) do
    OpenTelemetry::Instrumentation::Rack::Middlewares::Old::EventHandler.new
  end

  before { skip unless ENV['BUNDLE_GEMFILE'].include?('old') }

  it 'reports unexpected errors without causing request errors' do
    call_count = 0
    OpenTelemetry::Instrumentation::Rack.stub(:current_span, -> { raise 'Bad news!' }) do
      OpenTelemetry.stub(:handle_error, ->(*_args, **_kwargs) { call_count += 1 }) do
        handler.on_start(nil, nil)
        handler.on_commit(nil, nil)
        handler.on_send(nil, nil)
        handler.on_error(nil, nil, nil)
        handler.on_finish(nil, nil)
      end
    end
    assert_equal 5, call_count
  end
end

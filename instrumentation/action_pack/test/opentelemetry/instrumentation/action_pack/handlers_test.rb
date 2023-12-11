# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/action_pack'

describe 'OpenTelemetry::Instrumentation::ActionPack::Handlers' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionPack::Instrumentation.instance }
  let(:config) { {} }

  before do
    OpenTelemetry::Instrumentation::ActionPack::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)
  end

  it 'success subscribe the notification' do
    subscriptions = OpenTelemetry::Instrumentation::ActionPack::Handlers.instance_variable_get(:@subscriptions)
    _(subscriptions.count).must_equal 1
    _(subscriptions[0].pattern).must_equal 'process_action.action_controller'
  end

  it 'success unsubscribe the notification' do
    OpenTelemetry::Instrumentation::ActionPack::Handlers.unsubscribe
    subscriptions = OpenTelemetry::Instrumentation::ActionPack::Handlers.instance_variable_get(:@subscriptions)
    _(subscriptions).must_be_nil
  end
end

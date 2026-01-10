# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::ActionView::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::ActionView'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end

  describe '#compatible' do
    it 'when action_view is available' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe 'configuration' do
    it 'has default values' do
      _(instrumentation.config[:disallowed_notification_payload_keys]).must_equal []
      _(instrumentation.config[:notification_payload_transform]).must_be_nil
      _(instrumentation.config[:legacy_span_names]).must_equal false
    end
  end
end

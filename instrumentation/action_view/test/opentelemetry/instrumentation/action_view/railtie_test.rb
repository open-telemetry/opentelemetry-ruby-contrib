# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::ActionView::Railtie do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionView::Instrumentation.instance }

  it 'subscribes to all ActionView notification events' do
    subscriptions = OpenTelemetry::Instrumentation::ActionView::SUBSCRIPTIONS

    _(subscriptions).must_include 'render_template.action_view'
    _(subscriptions).must_include 'render_partial.action_view'
    _(subscriptions).must_include 'render_collection.action_view'
    _(subscriptions).must_include 'render_layout.action_view'
  end

  it 'creates subscriptions for each event' do
    OpenTelemetry::Instrumentation::ActionView::SUBSCRIPTIONS.each do |subscription_name|
      listeners = ActiveSupport::Notifications.notifier.listeners_for(subscription_name)

      _(listeners).wont_be_empty
      _(listeners.any? { |l| l.instance_variable_get(:@delegate).is_a?(OpenTelemetry::Instrumentation::ActiveSupport::SpanSubscriber) }).must_equal true
    end
  end

  it 'uses ActiveSupport instrumentation' do
    # Verify that ActiveSupport instrumentation is installed
    active_support_instrumentation = OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance
    _(active_support_instrumentation.installed?).must_equal true
  end

  describe 'subscription configuration' do
    it 'passes notification_payload_transform to subscriptions' do
      # The config should be accessible through the instrumentation instance
      _(instrumentation.config[:notification_payload_transform]).must_be_nil
    end

    it 'passes disallowed_notification_payload_keys to subscriptions' do
      _(instrumentation.config[:disallowed_notification_payload_keys]).must_equal []
    end

    it 'passes legacy_span_names to subscriptions' do
      _(instrumentation.config[:legacy_span_names]).must_equal false
    end
  end

  describe 'payload transformation' do
    it 'transforms mapped keys and omits unmapped keys' do
      transformed = OpenTelemetry::Instrumentation::ActionView::PAYLOAD_TRANSFORMER.call(
        { identifier: '/app/views/posts/index.html.erb', layout: 'application', count: 5, custom_key: 'value' }
      )

      _(transformed['code.filepath']).must_equal '/app/views/posts/index.html.erb'
      _(transformed['view.layout.code.filepath']).must_equal 'application'
      _(transformed['view.collection.count']).must_equal 5
      _(transformed).wont_include 'identifier'
      _(transformed).wont_include 'layout'
      _(transformed).wont_include 'count'
      _(transformed).wont_include 'custom_key'
    end
  end
end

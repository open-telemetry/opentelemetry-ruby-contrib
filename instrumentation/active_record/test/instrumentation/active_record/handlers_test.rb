# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

# Skip this entire test file if handlers aren't loaded
if defined?(OpenTelemetry::Instrumentation::ActiveRecord::Handlers)
  describe OpenTelemetry::Instrumentation::ActiveRecord::Handlers do
    let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance }

    describe '.subscribe' do
      it 'subscribes to sql.active_record when enabled' do
        skip 'notifications_instrumentation not enabled' unless instrumentation.config[:enable_notifications_instrumentation]

        # Verify that subscription exists
        subscribers = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record')
        
        assert subscribers.any?, 'Expected to find subscribers for sql.active_record'
      end

      it 'does not subscribe twice' do
        skip 'notifications_instrumentation not enabled' unless instrumentation.config[:enable_notifications_instrumentation]

        initial_count = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').size
        
        OpenTelemetry::Instrumentation::ActiveRecord::Handlers.subscribe
        
        final_count = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').size
        
        assert_equal initial_count, final_count, 'Should not subscribe twice'
      end
    end

    describe '.unsubscribe' do
      it 'removes subscriptions' do
        skip 'notifications_instrumentation not enabled' unless instrumentation.config[:enable_notifications_instrumentation]

        initial_count = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').size
        
        OpenTelemetry::Instrumentation::ActiveRecord::Handlers.unsubscribe
        
        final_count = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').size
        
        assert final_count < initial_count, 'Should have fewer subscribers after unsubscribe'
        
        # Re-subscribe for other tests
        OpenTelemetry::Instrumentation::ActiveRecord::Handlers.subscribe
      end
    end
  end
end

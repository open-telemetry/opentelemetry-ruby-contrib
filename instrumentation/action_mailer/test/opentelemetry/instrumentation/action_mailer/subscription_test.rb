# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-instrumentation-active_support'

describe OpenTelemetry::Instrumentation::ActionMailer do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionMailer::Instrumentation.instance }

  before do
    exporter.reset
  end

  describe 'deliver.action_mailer' do
    describe 'with default configuration' do
      it 'generates a deliver span' do
        subscribing_to_deliver do
          TestMailer.hello_world.deliver_now
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'deliver.action_mailer' }

        _(span).wont_be_nil

        _(span.attributes['email.x_mailer']).must_equal('TestMailer')
        _(span.attributes['email.subject']).must_equal('Hello world')
        _(span.attributes['email.message_id']).wont_be_empty
      end
    end

    describe 'with custom configuration' do
      it 'with email_address: :include' do
        with_configuration(email_address: :include, disallowed_notification_payload_keys: []) do
          subscribing_to_deliver do
            TestMailer.hello_world.deliver_now
          end
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'deliver.action_mailer' }

        _(span).wont_be_nil

        _(span.attributes['email.x_mailer']).must_equal('TestMailer')
        _(span.attributes['email.subject']).must_equal('Hello world')
        _(span.attributes['email.message_id']).wont_be_empty
        _(span.attributes['email.to.address']).must_equal(['to@example.com'])
        _(span.attributes['email.from.address']).must_equal(['from@example.com'])
        _(span.attributes['email.cc.address']).must_equal(['cc@example.com'])
        _(span.attributes['email.bcc.address']).must_equal(['bcc@example.com'])
      end

      it 'with a custom transform proc' do
        transform = ->(payload) { payload.transform_keys(&:upcase) }
        with_configuration(notification_payload_transform: transform) do
          instrumentation.send(:ecs_mail_convention)
          subscribing_to_deliver do
            TestMailer.hello_world.deliver_now
          end
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'deliver.action_mailer' }

        _(span).wont_be_nil

        _(span.attributes['EMAIL.X_MAILER']).must_equal('TestMailer')
        _(span.attributes['EMAIL.SUBJECT']).must_equal('Hello world')
        _(span.attributes['EMAIL.MESSAGE_ID']).wont_be_empty
      end
    end
  end

  describe 'process.action_mailer' do
    describe 'with default configuration' do
      it 'generates a process span' do
        transform = ->(payload) { payload.transform_keys(&:upcase) }
        with_configuration(disallowed_process_payload_keys: [:ARGS], process_payload_transform: transform) do
          subscribing_to_process do
            TestMailer.hello_world('Hola mundo').deliver_now
          end
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'process.action_mailer' }

        _(span).wont_be_nil

        _(span.attributes['MAILER']).must_equal('TestMailer')
        _(span.attributes['ACTION']).must_equal('hello_world')
        _(span.attributes['ARGS']).must_be_nil
      end
    end

    describe 'with custom configuration' do
      it 'generates a process span' do
        subscribing_to_process do
          TestMailer.hello_world('Hola mundo').deliver_now
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'process.action_mailer' }

        _(span).wont_be_nil

        _(span.attributes['mailer']).must_equal('TestMailer')
        _(span.attributes['action']).must_equal('hello_world')
        _(span.attributes['args']).must_equal(['Hola mundo'])
      end
    end
  end

  def with_configuration(values, &)
    original_config = instrumentation.instance_variable_get(:@config)
    modified_config = original_config.merge(values)
    instrumentation.instance_variable_set(:@config, modified_config)

    yield

    instrumentation.instance_variable_set(:@config, original_config)
  end

  def subscribing_to_deliver(&)
    subscription = OpenTelemetry::Instrumentation::ActionMailer::Railtie.subscribe_to_deliver
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  def subscribing_to_process(&)
    subscription = OpenTelemetry::Instrumentation::ActionMailer::Railtie.subscribe_to_process
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end
end

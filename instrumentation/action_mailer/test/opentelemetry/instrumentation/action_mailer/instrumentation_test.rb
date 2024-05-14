# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::ActionMailer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionMailer::Instrumentation.instance }
  let(:payload) do
    {
      mailer: 'TestMailer',
      message_id: '6638fab8d3cdb_f0b2c52420@8b5092010d2f.mail',
      subject: 'Welcome to OpenTelemetry!',
      to: ['test_mailer@otel.org'],
      from: ['no-reply@example.com'],
      bcc: ['bcc@example.com'],
      cc: ['cc@example.com'],
      perform_deliveries: true
    }
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::ActionMailer'
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

  describe '#install with default options' do
    it 'with default options' do
      _(instrumentation.config[:disallowed_notification_payload_keys]).wont_be_empty
      _(instrumentation.config[:email_address]).must_equal :omit
    end
  end

  describe '#resolve_email_address' do
    it 'with include' do
      original_config = instrumentation.instance_variable_get(:@config)
      modified_config = original_config.dup
      modified_config[:email_address] = :include
      modified_config[:disallowed_notification_payload_keys] = []
      instrumentation.instance_variable_set(:@config, modified_config)

      instrumentation.send(:resolve_email_address)
      _(instrumentation.config[:disallowed_notification_payload_keys].size).must_equal 0

      instrumentation.instance_variable_set(:@config, original_config)
    end
  end

  describe '#transform_payload' do
    it 'with simple payload' do
      payload = {
        mailer: 'TestMailer',
        message_id: '6638fab8d3cdb_f0b2c52420@8b5092010d2f.mail',
        subject: 'Welcome to OpenTelemetry!',
        to: ['test_mailer@otel.org'],
        from: ['no-reply@example.com'],
        bcc: ['bcc@example.com'],
        cc: ['cc@example.com'],
        perform_deliveries: true
      }
      tranformed_payload = instrumentation.send(:transform_payload, payload)

      _(tranformed_payload['email.message_id']).must_equal '6638fab8d3cdb_f0b2c52420@8b5092010d2f.mail'
      _(tranformed_payload['email.subject']).must_equal 'Welcome to OpenTelemetry!'
      _(tranformed_payload['email.x_mailer']).must_equal 'TestMailer'
      _(tranformed_payload['email.to.address'][0]).must_equal 'test_mailer@otel.org'
      _(tranformed_payload['email.from.address'][0]).must_equal 'no-reply@example.com'
      _(tranformed_payload['email.cc.address'][0]).must_equal 'cc@example.com'
      _(tranformed_payload['email.bcc.address'][0]).must_equal 'bcc@example.com'
    end
  end

  describe '#ecs_mail_convention' do
    it 'with user-defined payload' do
      original_config = instrumentation.instance_variable_get(:@config)
      modified_config = original_config.dup

      modified_config[:notification_payload_transform] = ->(payload) { payload['email.message_id'] = 'fake_message_id' }
      instrumentation.instance_variable_set(:@config, modified_config)

      instrumentation.send(:ecs_mail_convention)
      payload = { mailer: 'TestMailer' }

      tranformed_payload = instrumentation.config[:notification_payload_transform].call(payload)

      _(tranformed_payload['email.message_id']).must_equal 'fake_message_id'

      instrumentation.instance_variable_set(:@config, original_config)
    end

    it 'without user-defined payload' do
      tranformed_payload = instrumentation.config[:notification_payload_transform].call(payload)

      _(tranformed_payload['email.message_id']).must_equal '6638fab8d3cdb_f0b2c52420@8b5092010d2f.mail'
      _(tranformed_payload['email.subject']).must_equal 'Welcome to OpenTelemetry!'
      _(tranformed_payload['email.x_mailer']).must_equal 'TestMailer'
      _(tranformed_payload['email.to.address'][0]).must_equal 'test_mailer@otel.org'
      _(tranformed_payload['email.from.address'][0]).must_equal 'no-reply@example.com'
      _(tranformed_payload['email.cc.address'][0]).must_equal 'cc@example.com'
      _(tranformed_payload['email.bcc.address'][0]).must_equal 'bcc@example.com'
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::ActionMailer do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActionMailer::Instrumentation.instance }

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
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_storage'

describe OpenTelemetry::Instrumentation::ActiveStorage do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveStorage::Instrumentation.instance }
  let(:payload) do
    {
      checksum: 'BC3HWOZ8gHaD2PfLOgZP0w==',
      service: 'S3'
    }
  end

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::ActiveStorage'
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
      _(instrumentation.config[:key]).must_equal :omit
      _(instrumentation.config[:url]).must_equal :omit
    end
  end

  describe '#resolve_key' do
    it 'with include' do
      original_config = instrumentation.instance_variable_get(:@config)
      modified_config = original_config.dup
      modified_config[:key] = :include
      modified_config[:disallowed_notification_payload_keys] = []
      instrumentation.instance_variable_set(:@config, modified_config)

      instrumentation.send(:resolve_key)
      _(instrumentation.config[:disallowed_notification_payload_keys].size).must_equal 0

      instrumentation.instance_variable_set(:@config, original_config)
    end
  end

  describe '#resolve_url' do
    it 'with include' do
      original_config = instrumentation.instance_variable_get(:@config)
      modified_config = original_config.dup
      modified_config[:url] = :include
      modified_config[:disallowed_notification_payload_keys] = []
      instrumentation.instance_variable_set(:@config, modified_config)

      instrumentation.send(:resolve_url)
      _(instrumentation.config[:disallowed_notification_payload_keys].size).must_equal 0

      instrumentation.instance_variable_set(:@config, original_config)
    end
  end

  describe '#resolve_payload_transform' do
    it 'with user-defined payload' do
      original_config = instrumentation.instance_variable_get(:@config)
      modified_config = original_config.dup

      modified_config[:notification_payload_transform] = ->(payload) { payload['active_storage.checksum'] = 'fake_checksum' }
      instrumentation.instance_variable_set(:@config, modified_config)

      instrumentation.send(:resolve_payload_transform)
      payload = { checksum: 'real_checksum' }

      tranformed_payload = instrumentation.config[:notification_payload_transform].call(payload)

      _(tranformed_payload['active_storage.checksum']).must_equal 'fake_checksum'

      instrumentation.instance_variable_set(:@config, original_config)
    end

    it 'without user-defined payload' do
      transformed_payload = instrumentation.config[:notification_payload_transform].call(payload)

      _(transformed_payload['active_storage.checksum']).must_equal 'BC3HWOZ8gHaD2PfLOgZP0w=='
      _(transformed_payload['active_storage.service']).must_equal 'S3'
    end
  end

  describe '#transform_payload' do
    it 'adds active_storage. prefix to payload' do
      transformed_payload = instrumentation.send(:transform_payload, payload)

      _(transformed_payload['active_storage.checksum']).must_equal 'BC3HWOZ8gHaD2PfLOgZP0w=='
      _(transformed_payload['active_storage.service']).must_equal 'S3'
    end
  end
end

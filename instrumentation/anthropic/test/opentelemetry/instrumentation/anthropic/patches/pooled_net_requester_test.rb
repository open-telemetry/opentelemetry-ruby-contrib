# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../../lib/opentelemetry/instrumentation/anthropic'
require_relative '../../../../../lib/opentelemetry/instrumentation/anthropic/instrumentation'
require_relative '../../../../../lib/opentelemetry/instrumentation/anthropic/patches/pooled_net_requester'

describe OpenTelemetry::Instrumentation::Anthropic::Patches::PooledNetRequester do
  let(:patch) { OpenTelemetry::Instrumentation::Anthropic::Patches::PooledNetRequester }
  let(:instrumentation) { OpenTelemetry::Instrumentation::Anthropic::Instrumentation.instance }
  let(:anthropic_client) { Anthropic::Client.new(api_key: 'beep boop') }
  let(:tracer) { OpenTelemetry.tracer_provider.tracer('test', '0.1.0') }
  let(:spans) { EXPORTER.finished_spans }

  before do
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install({})
  end

  after { instrumentation.instance_variable_set(:@installed, false) }

  describe '#execute' do
    it 'should set the context in the fiber' do
      stub_request(:post, 'https://api.anthropic.com/v1/messages')
      tracer.in_span('test') do
        stream = anthropic_client.messages.stream(
          max_tokens: 1,
          messages: [{ role: 'user', content: 'Hello, Claude' }],
          model: :'beep boop'
        )
        stream.each do |event|
          event.delta.content
        end
      end

      test_span = spans.find { |span| span.name == 'test' }
      http_span = spans.find { |span| span.name == 'HTTP POST' }

      _(test_span.span_id).must_equal(http_span.parent_span_id)
    end
  end
end

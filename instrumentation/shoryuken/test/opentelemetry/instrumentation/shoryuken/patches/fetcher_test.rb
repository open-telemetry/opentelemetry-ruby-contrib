# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/shoryuken'
require_relative '../../../../../lib/opentelemetry/instrumentation/shoryuken/patches/fetcher'

describe OpenTelemetry::Instrumentation::Shoryuken::Patches::Fetcher do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Shoryuken::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:config) { {} }
  let(:fetcher) { MockLoader.new.fetcher }
  let(:queue) { Shoryuken::Client.queues('default') }
  let(:sqs_client) { Aws::SQS::Client.new(stub_responses: true) }

  before do
    # Clear spans
    exporter.reset
    instrumentation.install(config)
    Shoryuken::Client.sqs = sqs_client
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe 'fetch' do
    it 'does not trace' do
      allow(fetcher).to receive(:fetch_with_auto_retry)
      fetcher.fetch(queue, 10)
      _(spans.size).must_equal(0)
    end
  end
end

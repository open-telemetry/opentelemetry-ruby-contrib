# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/shoryuken'
require_relative '../../../../../lib/opentelemetry/instrumentation/shoryuken/patches/processor'

describe OpenTelemetry::Instrumentation::Shoryuken::Patches::Processor do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Shoryuken::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:span) { spans.first }
  let(:config) { {} }
  let(:queue_name) { 'default' }
  let(:sqs_msg) do
    double(
      Shoryuken::Message,
      queue_url: queue_name,
      body: '{"test" : 1}',
      message_attributes: {
        'shoryuken_class' => { string_value: worker_class.name }
      },
      message_id: SecureRandom.uuid,
      receipt_handle: SecureRandom.uuid
    )
  end
  let(:sqs_client) { Aws::SQS::Client.new(stub_responses: true) }
  let(:worker_class) { SimpleJob }

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

  describe '#process' do
    it 'does not trace' do
      allow(worker_class).to receive_message_chain(:server_middleware, :invoke)
      Shoryuken::Processor.process(queue_name, sqs_msg)
      _(spans.size).must_equal(0)
    end
  end
end

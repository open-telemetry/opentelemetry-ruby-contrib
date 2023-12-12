# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Handlers do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveJob::Instrumentation.instance }
  let(:config) { { propagation_style: :link, span_naming: :queue } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:publish_span) { spans.find { |s| s.name == 'default publish' } }
  let(:process_span) { spans.find { |s| s.name == 'default process' } }

  before do
    OpenTelemetry::Instrumentation::ActiveJob::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)
    ActiveJob::Base.queue_adapter = :async
    ActiveJob::Base.queue_adapter.immediate = true

    exporter.reset
  end

  after do
    begin
      ActiveJob::Base.queue_adapter.shutdown
    rescue StandardError
      nil
    end
    ActiveJob::Base.queue_adapter = :inline
  end

  describe 'compatibility' do
    it 'works with positional args' do
      _(PositionalOnlyArgsJob.perform_now('arg1')).must_be_nil # Make sure this runs without raising an error
    end

    it 'works with keyword args' do
      _(KeywordOnlyArgsJob.perform_now(keyword2: :keyword2)).must_be_nil # Make sure this runs without raising an error
    end

    it 'works with mixed args' do
      _(MixedArgsJob.perform_now('arg1', 'arg2', keyword2: :keyword2)).must_be_nil # Make sure this runs without raising an error
    end
  end
end

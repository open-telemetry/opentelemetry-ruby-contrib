# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Patches::Base do
  describe 'serialization / deserialization' do
    it 'must handle metadata' do
      job = TestJob.new
      job.__otel_headers = { 'foo' => 'bar' }

      serialized_job = job.serialize
      _(serialized_job.keys).must_include '__otel_headers'

      job = TestJob.new
      job.deserialize(serialized_job)
      _(job.__otel_headers).must_equal('foo' => 'bar')
    end

    it 'handles jobs queued without instrumentation' do # e.g. during a rolling deployment
      job = TestJob.new
      serialized_job = job.serialize
      serialized_job.delete('metadata')

      job = TestJob.new
      job.deserialize(serialized_job) # should not raise an error
    end
  end
end

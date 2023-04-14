# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_job'

describe OpenTelemetry::Instrumentation::ActiveJob::Patches::Base do
  describe 'attr_accessor' do
    it 'adds a "first_enqueued_at" accessor' do
      job = TestJob.new

      _(job).must_respond_to :first_enqueued_at
      _(job).must_respond_to :first_enqueued_at=
    end

    it 'adds a "metadata" accessor' do
      job = TestJob.new

      _(job).must_respond_to :metadata
      _(job).must_respond_to :metadata=
    end
  end

  describe 'serialization / deserialization' do
    it 'must handle first_enqueued_at' do
      job = TestJob.new
      timestamp = Time.utc(2023, 04, 14).iso8601(9)
      job.first_enqueued_at = timestamp

      serialized_job = job.serialize
      _(serialized_job.keys).must_include 'first_enqueued_at'

      job = TestJob.new
      job.deserialize(serialized_job)
      _(job.first_enqueued_at).must_equal(timestamp)
    end

    it 'must handle metadata' do
      job = TestJob.new
      job.metadata = { 'foo' => 'bar' }

      serialized_job = job.serialize
      _(serialized_job.keys).must_include 'metadata'

      job = TestJob.new
      job.deserialize(serialized_job)
      _(job.metadata).must_equal('foo' => 'bar')
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

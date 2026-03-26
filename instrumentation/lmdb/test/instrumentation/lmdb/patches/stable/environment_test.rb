# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/lmdb'
require_relative '../../../../../lib/opentelemetry/instrumentation/lmdb/patches/stable/environment'

describe 'OpenTelemetry::Instrumentation::LMDB::Patches::Stable::Environment' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::LMDB::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }

  let(:db_path) { File.join(File.dirname(__FILE__), '..', 'tmp', 'test') }
  let(:lmdb) { LMDB.new(db_path) }

  before do
    skip unless ENV['BUNDLE_GEMFILE']&.include?('stable')
    exporter.reset
    instrumentation.install({})
    FileUtils.rm_rf(db_path)
    FileUtils.mkdir_p(db_path)
  end

  after do
    FileUtils.rm_rf(db_path)
    lmdb.close
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#transaction' do
    it 'traces with stable attributes' do
      lmdb.transaction do
        lmdb.database['foo'] = 'bar'
      end

      _(span.name).must_equal('PUT foo')
      _(span.attributes['db.system.name']).must_equal('lmdb')
      _(span.attributes['db.query.text']).must_equal('PUT foo bar')

      _(last_span.name).must_equal('TRANSACTION')
      _(last_span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes['db.operation.name']).must_equal('TRANSACTION')
      _(last_span.attributes).wont_include('db.system')
      _(last_span.attributes).wont_include('peer.service')
    end
  end
end

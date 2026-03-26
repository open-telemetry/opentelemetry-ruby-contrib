# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/lmdb'
require_relative '../../../../../lib/opentelemetry/instrumentation/lmdb/patches/stable/database'

describe 'OpenTelemetry::Instrumentation::LMDB::Patches::Stable::Database' do
  let(:instrumentation) { OpenTelemetry::Instrumentation::LMDB::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:last_span) { exporter.finished_spans.last }
  let(:config) { {} }
  let(:db_path) { File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'test') }
  let(:lmdb) { LMDB.new(db_path) }

  before do
    skip unless ENV['BUNDLE_GEMFILE']&.include?('stable')
    exporter.reset
    instrumentation.install(config)
    FileUtils.rm_rf(db_path)
    FileUtils.mkdir_p(db_path)
  end

  after do
    FileUtils.rm_rf(db_path)
    lmdb.close
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#clear' do
    it 'traces with stable attributes' do
      lmdb.database.clear
      _(span.name).must_equal('CLEAR')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system.name']).must_equal('lmdb')
      _(span.attributes['db.query.text']).must_equal('CLEAR')
    end

    it 'omits db.query.text attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database.clear

      _(span.kind).must_equal(:client)
      _(span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.query.text')
    end
  end

  describe '#put' do
    it 'traces with stable attributes' do
      lmdb.database['foo'] = 'bar'
      _(span.name).must_equal('PUT foo')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system.name']).must_equal('lmdb')
      _(span.attributes['db.query.text']).must_equal('PUT foo bar')
    end

    it 'truncates long statements' do
      lmdb.database['foo'] = 'bar' * 200
      _(span.name).must_equal('PUT foo')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system.name']).must_equal('lmdb')
      _(span.attributes['db.query.text'].size).must_equal(500)
    end

    describe 'when peer_service config is set' do
      let(:config) { { peer_service: 'otel:lmdb' } }

      it 'does not add peer.service attribute in stable mode' do
        lmdb.database['foo'] = 'bar'
        _(span.name).must_equal('PUT foo')
        _(span.kind).must_equal(:client)
        _(span.attributes['db.system.name']).must_equal('lmdb')
        _(span.attributes['db.query.text']).must_equal('PUT foo bar')
        _(span.attributes).wont_include('peer.service')
      end
    end

    it 'omits db.query.text attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database['foo'] = 'bar'
      lmdb.database['foo']

      _(span.name).must_equal('PUT foo')
      _(span.kind).must_equal(:client)
      _(span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.query.text')
    end
  end

  describe '#get' do
    it 'traces with stable attributes' do
      lmdb.database['foo'] = 'bar'
      lmdb.database['foo']

      _(last_span.name).must_equal('GET foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes['db.query.text']).must_equal('GET foo')
      _(last_span.attributes).wont_include('db.system')
      _(last_span.attributes).wont_include('db.statement')
    end

    it 'omits db.query.text attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database['foo'] = 'bar'
      lmdb.database['foo']

      _(last_span.name).must_equal('GET foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.query.text')
    end
  end

  describe '#delete' do
    it 'traces with stable attributes' do
      lmdb.database['foo'] = 'bar'
      lmdb.database.delete('foo')

      _(last_span.name).must_equal('DELETE foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes['db.query.text']).must_equal('DELETE foo')
      _(last_span.attributes).wont_include('db.system')
      _(last_span.attributes).wont_include('db.statement')
    end

    it 'traces with value supplied' do
      lmdb.database['foo'] = 'bar'
      lmdb.database.delete('foo', 'bar')

      _(last_span.name).must_equal('DELETE foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes['db.query.text']).must_equal('DELETE foo bar')
    end

    it 'omits db.query.text attribute' do
      instrumentation.instance_variable_set(:@installed, false)
      instrumentation.install(db_statement: :omit)

      lmdb.database['foo'] = 'bar'
      lmdb.database.delete('foo')

      _(last_span.name).must_equal('DELETE foo')
      _(last_span.kind).must_equal(:client)
      _(last_span.attributes['db.system.name']).must_equal('lmdb')
      _(last_span.attributes).wont_include('db.query.text')
    end
  end
end

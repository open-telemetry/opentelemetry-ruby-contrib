# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch'
require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch/patches/client'
require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch/patches/deep_dup'
require_relative '../../../../lib/opentelemetry/instrumentation/elasticsearch/patches/sanitizer'

describe OpenTelemetry::Instrumentation::Elasticsearch::Patches::Client do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Elasticsearch::Instrumentation.instance }
  let(:http_instrumentation) { OpenTelemetry::Instrumentation::Faraday::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.find { |s| !s.name.include?('HTTP') } }
  let(:config) { {} }
  let(:client) do
    Elasticsearch::Client.new(log: false).tap do |client|
      client.instance_variable_set(:@verified, true)
    end
  end

  before do
    exporter.reset
    @orig_propagation = OpenTelemetry.propagation
    propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
    OpenTelemetry.propagation = propagator
    instrumentation.instance_variable_set(:@installed, false)
    http_instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(config)
    http_instrumentation.install
    stub_request(:get, %r{http://localhost:9200/.*}).to_return(status: 200)
    stub_request(:post, %r{http://localhost:9200/.*}).to_return(status: 200)
    stub_request(:put, %r{http://localhost:9200/.*}).to_return(status: 200)
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
    http_instrumentation.instance_variable_set(:@installed, false)

    OpenTelemetry.propagation = @orig_propagation
  end

  describe '#perform_request' do
    it 'traces a simple request' do
      client.search q: 'test'

      _(exporter.finished_spans.size).must_equal(2)
      _(span.name).must_equal 'GET _search'
      _(span.attributes['db.statement']).must_be_nil
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'GET'
      _(span.attributes['elasticsearch.method']).must_equal 'GET'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal "{\"q\":\"test\"}" # rubocop:disable Style/StringLiterals
      assert_requested(
        :get,
        'http://localhost:9200/_search?q=test'
      )
    end
  end

  describe 'set capture_es_spans to false' do
    let(:config) { { capture_es_spans: false } }

    it 'does not capture elasticsearch spans' do
      client.search q: 'test'

      _(exporter. finished_spans.size).must_equal(1)
      _(exporter.finished_spans.first.name).must_equal 'HTTP GET'
    end
  end

  describe 'set capture_es_spans to true' do
    let(:config) { { capture_es_spans: true } }

    it 'captures elasticsearch spans in addition to HTTP spans' do
      client.search q: 'test'

      _(exporter.finished_spans.count do |span|
        span.name == 'HTTP GET'
      end).must_equal(1)
      _(exporter.finished_spans.count do |span|
        span.name == 'GET _search'
      end).must_equal(1)
    end
  end

  describe 'set config to omit db statement' do
    let(:config) { { db_statement: :omit } }

    it 'omits the statement ' do
      client.bulk(
        body: [{
          index: { _index: 'users', data: { name: 'Fernando' } }
        }]
      )

      _(span.name).must_equal 'POST _bulk'
      _(span.attributes['db.statement']).must_be_nil
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'POST'
      _(span.attributes['elasticsearch.method']).must_equal 'POST'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal '{}'
      assert_requested(
        :post,
        'http://localhost:9200/_bulk'
      )
    end
  end

  describe 'set config to include entire db statement' do
    let(:config) { { db_statement: :include } }

    it 'includes the entire statement ' do
      client.bulk(
        body: [{
          index: { _index: 'users', data: { name: 'Emily', password: 'top_secret' } }
        }]
      )

      _(span.name).must_equal 'POST _bulk'
      _(span.attributes['db.statement']).must_equal(
        "{\"index\":{\"_index\":\"users\"}}\n{\"name\":\"Emily\",\"password\":\"top_secret\"}\n"
      )
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'POST'
      _(span.attributes['elasticsearch.method']).must_equal 'POST'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal '{}'
      assert_requested(
        :post,
        'http://localhost:9200/_bulk'
      )
    end
  end

  describe 'params and body as arguments' do
    it 'captures the span attributes' do
      client.bulk(
        refresh: true,
        body: [{ index: { _index: 'users', data: { name: 'Fernando' } } }]
      )

      _(span.name).must_equal 'POST _bulk'
      _(span.attributes['db.statement']).must_equal(
        "{\"index\":{\"_index\":\"users\"}}\n{\"name\":\"Fernando\"}\n"
      )
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'POST'
      _(span.attributes['elasticsearch.method']).must_equal 'POST'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal "{\"refresh\":true}" # rubocop:disable Style/StringLiterals
      assert_requested(
        :post,
        'http://localhost:9200/_bulk?refresh=true'
      )
    end
  end

  describe 'sanitize body' do
    it 'sanitizes certain fields' do
      client.index(
        index: 'users',
        id: '1',
        body: { name: 'Emily', password: 'top_secret' }
      )

      _(span.name).must_equal 'PUT users/_doc/1'
      _(span.attributes['db.statement']).must_equal(
        "{\"name\":\"Emily\",\"password\":\"?\"}" # rubocop:disable Style/StringLiterals
      )
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'PUT'
      _(span.attributes['elasticsearch.method']).must_equal 'PUT'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal '{}'
      assert_requested(
        :put,
        'http://localhost:9200/users/_doc/1'
      )
    end
  end

  describe 'custom sanitization fields' do
    let(:config) { { sanitize_field_names: ['abc*'] } }
    it 'sanitizes certain fields' do
      client.index(
        index: 'users',
        id: '1',
        body: { name: 'Emily', abcde: 'top_secret' }
      )

      _(span.name).must_equal 'PUT users/_doc/1'
      _(span.attributes['db.statement']).must_equal(
        "{\"name\":\"Emily\",\"abcde\":\"?\"}" # rubocop:disable Style/StringLiterals
      )
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'PUT'
      _(span.attributes['elasticsearch.method']).must_equal 'PUT'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal '{}'
      assert_requested(
        :put,
        'http://localhost:9200/users/_doc/1'
      )
    end
  end

  describe '#perform_request with exception' do
    before do
      stub_request(:get, %r{http://localhost:9200/.*})
        .to_return(status: [400, 'Bad Request'])
    end

    it 'adds an error event to the span' do
      begin
        client.search q: 'test'
      rescue StandardError # rubocop:disable Lint/SuppressedException
      end

      _(span.name).must_equal 'GET _search'
      _(span.attributes['db.statement']).must_be_nil
      _(span.attributes['db.system']).must_equal 'elasticsearch'
      _(span.attributes['db.operation']).must_equal 'GET'
      _(span.attributes['elasticsearch.method']).must_equal 'GET'
      _(span.attributes['net.transport']).must_equal 'ip_tcp'

      _(span.attributes['net.peer.name']).must_equal 'localhost'
      _(span.attributes['net.peer.port']).must_equal 9200

      _(span.attributes['elasticsearch.params']).must_equal "{\"q\":\"test\"}" # rubocop:disable Style/StringLiterals

      _(span.status.code).must_equal(
        OpenTelemetry::Trace::Status::ERROR
      )
      _(span.events.first.name).must_equal 'exception'
      _(span.events.first.attributes['exception.type']).must_equal 'Elastic::Transport::Transport::Errors::BadRequest'
      assert(!span.events.first.attributes['exception.message'].nil?)
      assert(!span.events.first.attributes['exception.stacktrace'].nil?)
    end
  end
end

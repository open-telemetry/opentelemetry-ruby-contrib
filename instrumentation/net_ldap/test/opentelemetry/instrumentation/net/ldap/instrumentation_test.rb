# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/net/ldap'
require_relative '../../../../../lib/opentelemetry/instrumentation/net/ldap/patches/instrumentation'

describe OpenTelemetry::Instrumentation::Net::LDAP::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Net::LDAP::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:span) { exporter.finished_spans.first }
  let(:ldap) do
    Net::LDAP.new \
      host: 'test.mocked.com', port: 636,
      encryption: {
        method: :simple_tls,
        tls_options: { foo: :bar }
      },
      force_no_page: true
  end

  # Fake Net::LDAP::Connection for testing
  class FakeConnection
    Result = Struct.new(:success?, :result_code)

    def initialize
      @bind_success = Result.new(true, Net::LDAP::ResultCodeSuccess)
      @search_success = Result.new(true, Net::LDAP::ResultCodeSizeLimitExceeded)
    end

    def bind(args = {})
      @bind_success
    end

    def search(*args)
      yield @search_success if block_given?
      @search_success
    end

    # for testing failure case
    def add(args)
      raise Net::LDAP::Error, 'Connection timed out - user specified timeout'
    end
  end

  before do
    exporter.reset
    instrumentation.install
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#instrument' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    describe 'when makeing bind' do
      it 'tracks the attributes with correct name' do
        ldap.connection = FakeConnection.new
        assert ldap.bind

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'bind.net_ldap'
        _(span.attributes['ldap.auth']).must_equal '{"method":"anonymous"}'
        _(span.attributes['ldap.base']).must_equal 'dc=com'
        _(span.attributes['ldap.encryption']).must_equal '{"method":"simple_tls","tls_options":{"foo":"bar"}}'
        _(span.attributes['ldap.payload']).must_equal '{}'
        _(span.attributes['ldap.status_code']).must_equal 0
        _(span.attributes['net.peer.name']).must_equal 'test.mocked.com'
        _(span.attributes['net.peer.port']).must_equal 636
      end
    end

    describe 'when making search' do
      it 'tracks the attributes with correct name' do
        ldap.connection = FakeConnection.new
        assert ldap.search(filter: '(uid=user1)')

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'search.net_ldap'
        _(span.attributes['ldap.auth']).must_equal '{"method":"anonymous"}'
        _(span.attributes['ldap.base']).must_equal 'dc=com'
        _(span.attributes['ldap.encryption']).must_equal '{"method":"simple_tls","tls_options":{"foo":"bar"}}'
        _(span.attributes['ldap.payload']).must_equal '{"filter":"(uid=user1)","paged_searches_supported":false,"base":"dc=com"}'
        _(span.attributes['ldap.status_code']).must_equal 0
        _(span.attributes['net.peer.name']).must_equal 'test.mocked.com'
        _(span.attributes['net.peer.port']).must_equal 636
      end
    end

    describe 'when error happens' do
      it 'tracks the attributes with correct name & error message' do
        ldap.connection = FakeConnection.new

        assert_raises Net::LDAP::Error do
          ldap.add({})
        end

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'add.net_ldap'
        _(span.attributes['ldap.auth']).must_equal '{"method":"anonymous"}'
        _(span.attributes['ldap.base']).must_equal 'dc=com'
        _(span.attributes['ldap.encryption']).must_equal '{"method":"simple_tls","tls_options":{"foo":"bar"}}'
        _(span.attributes['ldap.payload']).must_equal '{}'
        _(span.attributes['ldap.error_message']).must_equal 'Net::LDAP::Error: Connection timed out - user specified timeout'
        _(span.attributes['net.peer.name']).must_equal 'test.mocked.com'
        _(span.attributes['net.peer.port']).must_equal 636
      end
    end
  end
end

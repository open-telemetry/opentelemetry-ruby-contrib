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
      auth: {
        method: :simple,
        username: 'test_user',
        password: 'test_password'
      },
      force_no_page: true
  end

  # Fake Net::LDAP::Connection for testing
  class FakeConnection
    Result = Struct.new(:success?, :result_code)

    def initialize
      @bind_success = Result.new(true, Net::LDAP::ResultCodeSuccess)
      @modify_success = Result.new(true, Net::LDAP::ResultCodeSuccess)
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

    # for testing redaction
    def modify(args)
      @modify_success
    end
  end

  before do
    exporter.reset
    instrumentation.install(peer_service: 'test:ldap')
  end

  after do
    # Force re-install of instrumentation
    instrumentation.instance_variable_set(:@installed, false)
  end

  describe '#instrument' do
    it 'before request' do
      _(exporter.finished_spans.size).must_equal 0
    end

    describe 'when making bind' do
      it 'tracks the attributes with correct name' do
        ldap.connection = FakeConnection.new
        assert ldap.bind

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'LDAP bind'
        _(span.kind).must_equal :client
        _(span.attributes['ldap.auth.username']).must_equal 'test_user'
        _(span.attributes['ldap.auth.method']).must_equal 'simple'
        _(span.attributes.values).wont_include 'test_password'
        _(span.attributes['ldap.operation.type']).must_equal 'bind'
        _(span.attributes['ldap.request.message']).must_equal '{}'
        _(span.attributes['ldap.response.status_code']).must_equal 0
        _(span.attributes['ldap.tree.base']).must_equal 'dc=com'
        _(span.attributes['network.protocol.name']).must_equal 'ldap'
        _(span.attributes['network.protocol.version']).must_equal 3
        _(span.attributes['network.transport']).must_equal 'tcp'
        _(span.attributes['peer.service']).must_equal 'test:ldap'
        _(span.attributes['server.address']).must_equal 'test.mocked.com'
        _(span.attributes['server.port']).must_equal 636
      end
    end

    describe 'when making search' do
      it 'tracks the attributes with correct name' do
        ldap.connection = FakeConnection.new
        assert ldap.search(filter: '(uid=user1)')

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'LDAP search'
        _(span.kind).must_equal :client
        _(span.attributes['ldap.auth.username']).must_equal 'test_user'
        _(span.attributes['ldap.auth.method']).must_equal 'simple'
        _(span.attributes.values).wont_include 'test_password'
        _(span.attributes['ldap.operation.type']).must_equal 'search'
        _(span.attributes['ldap.request.message']).must_equal '{"filter":"(uid=user1)","paged_searches_supported":false,"base":"dc=com"}'
        _(span.attributes['ldap.response.status_code']).must_equal 0
        _(span.attributes['ldap.tree.base']).must_equal 'dc=com'
        _(span.attributes['network.protocol.name']).must_equal 'ldap'
        _(span.attributes['network.protocol.version']).must_equal 3
        _(span.attributes['network.transport']).must_equal 'tcp'
        _(span.attributes['peer.service']).must_equal 'test:ldap'
        _(span.attributes['server.address']).must_equal 'test.mocked.com'
        _(span.attributes['server.port']).must_equal 636
      end

      it 'should not throw an error when JSON could not be generated' do
        ldap.connection = FakeConnection.new
        binary_objectsid = Random.new(Minitest.seed).bytes(16).force_encoding(Encoding::BINARY)
        filter = Net::LDAP::Filter.eq('objectSid', binary_objectsid)
        assert ldap.search(filter: filter)

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'LDAP search'
        _(span.kind).must_equal :client
        _(span.attributes['ldap.auth.username']).must_equal 'test_user'
        _(span.attributes['ldap.auth.method']).must_equal 'simple'
        _(span.attributes.values).wont_include 'test_password'
        _(span.attributes['ldap.operation.type']).must_equal 'search'
        _(span.attributes['ldap.request.message']).must_be_nil
        _(span.attributes['ldap.response.status_code']).must_equal 0
        _(span.attributes['ldap.tree.base']).must_equal 'dc=com'
        _(span.attributes['network.protocol.name']).must_equal 'ldap'
        _(span.attributes['network.protocol.version']).must_equal 3
        _(span.attributes['network.transport']).must_equal 'tcp'
        _(span.attributes['peer.service']).must_equal 'test:ldap'
        _(span.attributes['server.address']).must_equal 'test.mocked.com'
        _(span.attributes['server.port']).must_equal 636
      end
    end

    describe 'when error happens' do
      it 'tracks the attributes with correct name & error message' do
        ldap.connection = FakeConnection.new

        assert_raises Net::LDAP::Error do
          ldap.add({})
        end

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'LDAP add'
        _(span.kind).must_equal :client
        _(span.attributes['error.message']).must_equal 'Connection timed out - user specified timeout'
        _(span.attributes['error.type']).must_equal 'Net::LDAP::Error'
        _(span.attributes['ldap.auth.username']).must_equal 'test_user'
        _(span.attributes['ldap.auth.method']).must_equal 'simple'
        _(span.attributes.values).wont_include 'test_password'
        _(span.attributes['ldap.operation.type']).must_equal 'add'
        _(span.attributes['ldap.request.message']).must_equal '{}'
        _(span.attributes['ldap.tree.base']).must_equal 'dc=com'
        _(span.attributes['network.protocol.name']).must_equal 'ldap'
        _(span.attributes['network.protocol.version']).must_equal 3
        _(span.attributes['network.transport']).must_equal 'tcp'
        _(span.attributes['peer.service']).must_equal 'test:ldap'
        _(span.attributes['server.address']).must_equal 'test.mocked.com'
        _(span.attributes['server.port']).must_equal 636
      end
    end

    describe 'when modify happens' do
      it 'tracks the attributes with correct name & redacts sensitive information' do
        ldap.connection = FakeConnection.new
        ops = [
          [:replace, :unicodePwd, ['P@ssw0rd']]
        ]
        assert ldap.modify(dn: 'CN=test,OU=test,DC=com', operations: ops)

        _(exporter.finished_spans.size).must_equal 1
        _(span.name).must_equal 'LDAP modify'
        _(span.kind).must_equal :client
        _(span.attributes['ldap.auth.username']).must_equal 'test_user'
        _(span.attributes['ldap.auth.method']).must_equal 'simple'
        _(span.attributes.values).wont_include 'test_password'
        _(span.attributes['ldap.operation.type']).must_equal 'modify'
        _(span.attributes['ldap.request.message']).must_equal '{"dn":"CN=test,OU=test,DC=com","operations":[["replace","unicodePwd",["[REDACTED]"]]]}'
        _(span.attributes['ldap.response.status_code']).must_equal 0
        _(span.attributes['ldap.tree.base']).must_equal 'dc=com'
        _(span.attributes['network.protocol.name']).must_equal 'ldap'
        _(span.attributes['network.protocol.version']).must_equal 3
        _(span.attributes['network.transport']).must_equal 'tcp'
        _(span.attributes['peer.service']).must_equal 'test:ldap'
        _(span.attributes['server.address']).must_equal 'test.mocked.com'
        _(span.attributes['server.port']).must_equal 636
      end
    end
  end
end

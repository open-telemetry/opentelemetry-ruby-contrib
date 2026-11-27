# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/http'

describe OpenTelemetry::Instrumentation::HTTP::HttpHelper do
  describe '.metric_attrs' do
    let(:response_class) { Struct.new(:code, :version) }

    it 'includes response attributes for a successful response' do
      response = response_class.new('200', '1.1')

      _(OpenTelemetry::Instrumentation::HTTP::HttpHelper.metric_attrs('GET', 'example.com', 80, response, nil)).must_equal(
        'http.request.method' => 'GET',
        'server.address' => 'example.com',
        'server.port' => 80,
        'http.response.status_code' => 200,
        'network.protocol.version' => '1.1'
      )
    end

    it 'sets error.type to the status code for an error response' do
      response = response_class.new('503', '1.1')

      attributes = OpenTelemetry::Instrumentation::HTTP::HttpHelper.metric_attrs('GET', 'example.com', 80, response, nil)
      _(attributes['error.type']).must_equal '503'
    end

    it 'sets error.type to the error class and omits response attributes without a response' do
      attributes = OpenTelemetry::Instrumentation::HTTP::HttpHelper.metric_attrs('GET', 'example.com', 443, nil, 'OpenTimeout')

      _(attributes).must_equal(
        'http.request.method' => 'GET',
        'server.address' => 'example.com',
        'server.port' => 443,
        'error.type' => 'OpenTimeout'
      )
    end

    it 'omits a nil server.address' do
      attributes = OpenTelemetry::Instrumentation::HTTP::HttpHelper.metric_attrs('GET', nil, 80, nil, nil)

      _(attributes.key?('server.address')).must_equal false
    end
  end
end

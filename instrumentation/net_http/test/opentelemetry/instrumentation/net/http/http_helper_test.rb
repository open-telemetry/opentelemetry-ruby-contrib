# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/net/http'

describe OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper do
  describe '.request_path' do
    it 'returns the request URI for URI-like paths' do
      path = Class.new do
        def request_uri = '/success?hello=there'
      end.new

      _(OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper.request_path(path)).must_equal '/success?hello=there'
    end

    it 'returns nil when a URI-like path has no HTTP request URI' do
      path = Class.new do
        def request_uri = nil
      end.new

      _(OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper.request_path(path)).must_be_nil
    end
  end

  describe '.split_path_and_query' do
    it 'splits a URI-like request path' do
      path = Class.new do
        def request_uri = '/success?hello=there'
      end.new

      _(OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper.split_path_and_query(path)).must_equal ['/success', 'hello=there']
    end

    it 'returns nil components when a URI-like path has no HTTP request URI' do
      path = Class.new do
        def request_uri = nil
      end.new

      _(OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper.split_path_and_query(path)).must_equal [nil, nil]
    end
  end
end

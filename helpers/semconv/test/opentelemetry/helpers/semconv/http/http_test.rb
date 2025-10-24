# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/helpers/semconv/http'

describe OpenTelemetry::Helpers::Semconv::HTTP do
  describe 'span naming' do
    test_cases = [
      # [description, attributes, expected_result]
      ['uses latest semconv naming', { 'http.request.method' => 'GET', 'url.template' => '/users/:id' }, 'GET /users/:id'],
      ['uses a mix of deprecated and latest semconv to name the span', { 'http.method' => 'POST', 'url.template' => '/api/v1/posts' }, 'POST /api/v1/posts'],
      ['prefers latest semconv over deprecated', { 'http.request.method' => 'PUT', 'http.method' => 'GET', 'url.template' => '/users/:id' }, 'PUT /users/:id'],
      ['uses the url template even if no HTTP method is present (edge case)', { 'url.template' => '/health' }, 'HTTP /health'],
      ['uses the HTTP request method', { 'http.request.method' => 'DELETE' }, 'DELETE'],
      ['supports the deprecated HTTP request method', { 'http.method' => 'PATCH' }, 'PATCH'],
      ['has a default HTTP span name when no attributes are present', {}, 'HTTP'],
      ['Empty method value (edge case)', { 'http.request.method' => '', 'url.template' => '/api/status' }, 'HTTP /api/status'],
      ['uses default HTTP span name with invalid or blank attributes', { 'http.request.method' => '  ', 'url.template' => '' }, 'HTTP'],
      ['uses the default HTTP span name when non-standard method is present', { 'http.request.method' => 'CUSTOM', 'url.template' => '/custom/endpoint' }, 'HTTP /custom/endpoint'],
      ['normalizes to uppercase method names', { 'http.request.method' => 'get', 'url.template' => '/lowercase' }, 'GET /lowercase'],
      ['requires string keys for attributes', { 'http.request.method': 'GET', 'url.template': '/symbol/keys' }, 'HTTP']
    ]

    test_cases.each do |description, attributes, expected|
      it description do
        _(OpenTelemetry::Helpers::Semconv::HTTP.name_from(attributes)).must_equal expected
      end
    end

    it 'normalizes HTTP methods to uppercase' do
      %w[GET POST PUT PATCH DELETE HEAD OPTIONS TRACE CONNECT].each do |method|
        attrs = { 'http.request.method' => method }
        _(OpenTelemetry::Helpers::Semconv::HTTP.name_from(attrs)).must_equal method

        attrs = { 'http.request.method' => method.downcase }
        _(OpenTelemetry::Helpers::Semconv::HTTP.name_from(attrs)).must_equal method

        attrs = { 'http.method' => method }
        _(OpenTelemetry::Helpers::Semconv::HTTP.name_from(attrs)).must_equal method

        attrs = { 'http.method' => method.downcase }
        _(OpenTelemetry::Helpers::Semconv::HTTP.name_from(attrs)).must_equal method
      end
    end

    it 'defaults to HTTP for unknown methods' do
      %w[PURGE FAKE PHONY].each do |method|
        attrs = { 'http.request.method' => method }
        _(OpenTelemetry::Helpers::Semconv::HTTP.name_from(attrs)).must_equal 'HTTP'
      end

      _(OpenTelemetry::Helpers::Semconv::HTTP.name_from({})).must_equal 'HTTP'
    end
  end
end

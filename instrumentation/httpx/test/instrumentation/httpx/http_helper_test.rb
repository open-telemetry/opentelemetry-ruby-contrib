# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../lib/opentelemetry/instrumentation/httpx'

describe OpenTelemetry::Instrumentation::HTTPX::HttpHelper do
  describe '.span_attrs_for_old' do
    it 'returns correct attributes for standard HTTP method' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_old('GET')

      _(result.span_name).must_equal 'HTTP GET'
      _(result.attributes['http.method']).must_equal 'GET'
    end

    it 'returns _OTHER for non-standard HTTP method' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_old('PURGE')

      _(result.span_name).must_equal 'HTTP'
      _(result.attributes['http.method']).must_equal '_OTHER'
    end

    it 'normalizes symbol methods' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_old(:get)

      _(result.span_name).must_equal 'HTTP GET'
      _(result.attributes['http.method']).must_equal 'GET'
    end

    it 'merges client context attributes' do
      client_context_attrs = { 'test.attribute' => 'test.value' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_old('GET')
        _(result.attributes['test.attribute']).must_equal 'test.value'
      end
    end

    it 'does not override client context http.method' do
      client_context_attrs = { 'http.method' => 'OVERRIDE' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_old('GET')
        _(result.attributes['http.method']).must_equal 'OVERRIDE'
      end
    end
  end

  describe '.span_attrs_for_stable' do
    it 'returns correct attributes for standard HTTP method' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_stable('GET')

      _(result.span_name).must_equal 'GET'
      _(result.attributes['http.request.method']).must_equal 'GET'
    end

    it 'returns _OTHER for non-standard HTTP method' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_stable('PURGE')

      _(result.span_name).must_equal 'HTTP'
      _(result.attributes['http.request.method']).must_equal '_OTHER'
      _(result.attributes['http.request.method_original']).must_equal 'PURGE'
    end

    it 'normalizes symbol methods' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_stable(:post)

      _(result.span_name).must_equal 'POST'
      _(result.attributes['http.request.method']).must_equal 'POST'
    end

    it 'includes url.template in span name when present' do
      client_context_attrs = { 'url.template' => '/users/{id}' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_stable('GET')
        _(result.span_name).must_equal 'GET /users/{id}'
      end
    end

    it 'includes url.template in span name for non-standard method' do
      client_context_attrs = { 'url.template' => '/cache/{key}' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_stable('PURGE')
        _(result.span_name).must_equal 'HTTP /cache/{key}'
      end
    end

    it 'does not override client context http.request.method' do
      client_context_attrs = { 'http.request.method' => 'OVERRIDE' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_stable('GET')
        _(result.attributes['http.request.method']).must_equal 'OVERRIDE'
      end
    end
  end

  describe '.span_attrs_for_dup' do
    it 'returns both old and stable attributes for standard HTTP method' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_dup('GET')

      _(result.span_name).must_equal 'GET'
      _(result.attributes['http.method']).must_equal 'GET'
      _(result.attributes['http.request.method']).must_equal 'GET'
    end

    it 'returns _OTHER for non-standard HTTP method' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_dup('PURGE')

      _(result.span_name).must_equal 'HTTP'
      _(result.attributes['http.method']).must_equal '_OTHER'
      _(result.attributes['http.request.method']).must_equal '_OTHER'
      _(result.attributes['http.request.method_original']).must_equal 'PURGE'
    end

    it 'normalizes symbol methods' do
      result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_dup(:put)

      _(result.span_name).must_equal 'PUT'
      _(result.attributes['http.method']).must_equal 'PUT'
      _(result.attributes['http.request.method']).must_equal 'PUT'
    end

    it 'includes url.template in span name when present' do
      client_context_attrs = { 'url.template' => '/users/{id}' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_dup('GET')
        _(result.span_name).must_equal 'GET /users/{id}'
      end
    end

    it 'merges client context attributes' do
      client_context_attrs = { 'test.attribute' => 'test.value' }

      OpenTelemetry::Common::HTTP::ClientContext.with_attributes(client_context_attrs) do
        result = OpenTelemetry::Instrumentation::HTTPX::HttpHelper.span_attrs_for_dup('GET')
        _(result.attributes['test.attribute']).must_equal 'test.value'
      end
    end
  end
end

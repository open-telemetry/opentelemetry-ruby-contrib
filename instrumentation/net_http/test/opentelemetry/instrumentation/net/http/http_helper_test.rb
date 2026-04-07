# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../../lib/opentelemetry/instrumentation/net/http/http_helper'

describe OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper do
  let(:helper) { OpenTelemetry::Instrumentation::Net::HTTP::HttpHelper }

  describe '.span_attrs_for_stable' do
    it 'normalizes known methods from symbol and lowercase string' do
      data_sym = helper.span_attrs_for_stable(:get)
      _(data_sym.span_name).must_equal 'GET'
      _(data_sym.attributes['http.request.method']).must_equal 'GET'

      data_str = helper.span_attrs_for_stable('get')
      _(data_str.span_name).must_equal 'GET'
      _(data_str.attributes['http.request.method']).must_equal 'GET'
    end

    it 'handles unknown methods and sets original' do
      data = helper.span_attrs_for_stable('purge')
      _(data.span_name).must_equal 'HTTP'
      _(data.attributes['http.request.method']).must_equal '_OTHER'
      _(data.attributes['http.request.method_original']).must_equal 'purge'
    end

    it 'includes url.template in span name from client context' do
      OpenTelemetry::Common::HTTP::ClientContext.with_attributes('url.template' => '/widgets/{id}') do
        data = helper.span_attrs_for_stable('GET')
        _(data.span_name).must_equal 'GET /widgets/{id}'
        _(data.attributes['url.template']).must_equal '/widgets/{id}'
      end
    end
  end

  describe '.span_attrs_for_old' do
    it 'builds old-style span name and attributes' do
      data = helper.span_attrs_for_old('GET')
      _(data.span_name).must_equal 'HTTP GET'
      _(data.attributes['http.method']).must_equal 'GET'
    end

    it 'handles unknown methods with _OTHER' do
      data = helper.span_attrs_for_old(:purge)
      _(data.span_name).must_equal 'HTTP'
      _(data.attributes['http.method']).must_equal '_OTHER'
    end
  end

  describe '.span_attrs_for_dup' do
    it 'sets both old and stable method attributes' do
      data = helper.span_attrs_for_dup('POST')
      _(data.span_name).must_equal 'POST'
      _(data.attributes['http.method']).must_equal 'POST'
      _(data.attributes['http.request.method']).must_equal 'POST'
    end

    it 'captures original method for unknown methods' do
      data = helper.span_attrs_for_dup('weird')
      _(data.span_name).must_equal 'HTTP'
      _(data.attributes['http.method']).must_equal '_OTHER'
      _(data.attributes['http.request.method']).must_equal '_OTHER'
      _(data.attributes['http.request.method_original']).must_equal 'weird'
    end
  end
end


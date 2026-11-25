# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/racecar/symbol_key_getter'

describe OpenTelemetry::Instrumentation::Racecar::SymbolKeyGetter do
  let(:getter) { OpenTelemetry::Instrumentation::Racecar::SymbolKeyGetter }
  let(:carrier) { { foo: 'bar' } }

  describe '#get' do
    it 'retrieves the value' do
      _(getter.get(carrier, 'foo')).must_equal('bar')
    end

    it 'returns nil for a missing key' do
      _(getter.get(carrier, 'baz')).must_be_nil
    end
  end

  describe '#keys' do
    it 'returns all the keys as strings' do
      _(getter.keys(carrier)).must_equal(['foo'])
    end
  end
end

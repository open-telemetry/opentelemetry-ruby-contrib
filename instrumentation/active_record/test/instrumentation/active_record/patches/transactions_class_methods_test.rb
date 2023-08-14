# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/transactions_class_methods'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::TransactionsClassMethods do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe '.transaction' do
    it 'traces' do
      User.transaction { User.create! }

      transaction_span = spans.find { |s| s.attributes['code.namespace'] == 'User' }
      _(transaction_span).wont_be_nil
    end

    it 'traces base transactions' do
      ActiveRecord::Base.transaction { User.create! }

      transaction_span = spans.find { |s| s.name == 'ActiveRecord.transaction' }
      _(transaction_span).wont_be_nil
    end

    it 'traces dynamically created transaction classes' do
      klass = Class.new(User) do
        def self.name
          'Klass'
        end
      end
      klass.transaction { klass.create! }

      transaction_span = spans.find { |s| s.attributes['code.namespace'] == 'Klass' }
      _(transaction_span).wont_be_nil
    end

    it 'records transaction name as code namespace' do
      ActiveRecord::Base.transaction { User.create! }

      transaction_span = spans.find { |s| s.attributes['code.namespace'] == 'ActiveRecord::Base' }
      _(transaction_span).wont_be_nil
    end
  end
end

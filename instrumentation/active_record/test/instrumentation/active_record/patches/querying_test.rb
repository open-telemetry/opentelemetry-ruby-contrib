# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/querying'

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::Querying do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }

  before { exporter.reset }

  describe 'query' do
    it 'traces' do
      Account.create!

      User.find_by_sql('SELECT * FROM users')
      Account.first.users.to_a

      user_find_spans = spans.select { |s| s.name == 'User query' }
      account_find_span = spans.find { |s| s.name == 'Account query' }

      _(user_find_spans.length).must_equal(2)
      _(account_find_span).wont_be_nil
    end
  end
end

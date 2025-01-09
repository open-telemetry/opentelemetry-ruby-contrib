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
  after do
    ActiveRecord::Base.subclasses.each do |model|
      model.connection.truncate(model.table_name)
    end
  end

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

    describe 'find_by_sql' do
      it 'creates a span' do
        Account.create!

        Account.find_by_sql('SELECT * FROM accounts')

        account_find_span = spans.find { |s| s.name == 'Account query' }
        _(account_find_span).wont_be_nil
        _(account_find_span.attributes).must_be_empty
      end

      describe 'given a block' do
        it 'creates a span' do
          account = Account.create!

          record_ids = []

          Account.find_by_sql('SELECT * FROM accounts') do |record|
            record_ids << record.id
          end

          account_find_span = spans.find { |s| s.name == 'Account query' }
          _(account_find_span).wont_be_nil
          _(account_find_span.attributes).must_be_empty

          _(record_ids).must_equal([account.id])
        end
      end
    end

    describe 'find_by' do
      it 'creates a span' do
        account = Account.create!
        User.create!(account: account)

        Account.find_by(id: account.id)

        account_find_span = spans.find { |s| s.name == 'Account query' }
        _(account_find_span).wont_be_nil
        _(account_find_span.attributes).must_be_empty
      end
    end

    describe 'find' do
      it 'creates a span' do
        account = Account.create!
        User.create!(account: account)

        Account.find(account.id)

        account_find_span = spans.find { |s| s.name == 'Account query' }
        _(account_find_span).wont_be_nil
        _(account_find_span.attributes).must_be_empty
      end

      describe 'given a block' do
        it 'creates a span' do
          account = Account.create!
          User.create!(account: account)

          record_ids = []

          Account.find(account.id) do |record|
            record_ids << record.id
          end

          account_find_span = spans.find { |s| s.name == 'Account query' }
          _(account_find_span).wont_be_nil
          _(account_find_span.attributes).must_be_empty
          _(record_ids).must_equal([account.id])
        end
      end
    end
  end
end

# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/instrumentation/active_record/handlers'

describe OpenTelemetry::Instrumentation::ActiveRecord::Handlers::SqlHandler do
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance }
  let(:config) { { enable_notifications_instrumentation: true } }
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans.select { |s| s.name == 'sql.active_record' } }

  before do
    # Capture original config before modification
    @original_config = instrumentation.config.dup

    OpenTelemetry::Instrumentation::ActiveRecord::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)
    User.delete_all
    Account.delete_all
    exporter.reset
  end

  after do
    # Restore original configuration and reinstall
    OpenTelemetry::Instrumentation::ActiveRecord::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, @original_config)
    instrumentation.instance_variable_set(:@installed, false)
    instrumentation.install(@original_config)

    # Clear any test data
    User.delete_all
    Account.delete_all
  end

  describe 'when sql.active_record notifications are emitted' do
    it 'creates spans with operation name from payload' do
      User.create!(name: 'otel')

      _(spans).wont_be_empty
    end

    it 'records async attribute when query is async' do
      # Create a user first so there's data to load
      Account.transaction do
        account = Account.create!
        User.create!(name: 'otel', account: account)
      end

      exporter.reset

      ActiveRecord::Base.asynchronous_queries_tracker.start_session
      relations = [
        User.limit(1).load_async,
        User.where(name: 'otel').includes(:account).load_async
      ]
      # Now wait for completion
      result = relations.flat_map(&:to_a)
      ActiveRecord::Base.asynchronous_queries_tracker.finalize_session(true)

      _(result).wont_be_empty

      # Trigger a real async query

      # The query should have run asynchronously
      async_spans = spans.select { |span| span.attributes['rails.active_record.query.async'] == true }
      _(async_spans).wont_be_empty
    end

    it 'records cached attribute when query is cached' do
      # First query - not cached
      User.first

      exporter.reset

      # Second query with caching enabled - should be cached
      User.cache do
        User.first
        User.first
      end

      cached_spans = spans.select { |s| s.attributes['rails.active_record.query.cached'] == true }
      _(cached_spans).wont_be_empty
    end

    it 'records synchronous queries' do
      _(User.all.to_a).must_be_empty

      values = spans.map { |span| span.attributes['rails.active_record.query.async'] }.uniq
      _(values).must_equal [false]
    end

    it 'records actual queries' do
      _(User.all.to_a).must_be_empty

      values = spans.map { |span| span.attributes['rails.active_record.query.cached'] }.uniq
      _(values).must_equal [false]
    end

    it 'records exceptions on spans' do
      # Create a scenario that will cause a SQL error
      begin
        ActiveRecord::Base.connection.execute('SELECT * FROM nonexistent_table')
      rescue StandardError
        # Expected to fail
      end

      error_spans = spans.select { |s| s.status.code == OpenTelemetry::Trace::Status::ERROR }
      _(error_spans).wont_be_empty
    end

    it 'sets span kind to internal' do
      User.first

      sql_spans = spans.reject { |s| s.attributes['db.operation'] == 'ActiveRecord::Base.transaction' }
      _(sql_spans).wont_be_empty

      sql_spans.each do |span|
        _(span.kind).must_equal :internal
      end
    end

    it 'uses SQL as default name when name is not present' do
      # Manually trigger a notification without a name
      ActiveRecord::Base.connection.execute('SELECT 1')

      _(spans.map { |s| s.attributes['db.operation'] }).must_equal ['SQL']
    end

    it 'creates nested spans correctly' do
      Account.transaction do
        account = Account.create!
        User.create!(name: 'otel', account: account)
      end

      # Verify parent-child relationships
      transaction_span = spans.find { |s| s.attributes['db.operation'] == 'TRANSACTION' }
      _(transaction_span).wont_be_nil

      create_spans = spans.select { |s| s.attributes['db.operation'].include?('Create') }

      _(create_spans.map { |s| s.attributes['db.operation'] }).must_equal(['Account Create', 'User Create'])
      _(create_spans.map(&:parent_span_id)).must_equal([transaction_span.span_id, transaction_span.span_id])
    end
  end

  describe 'with complex queries' do
    before do
      Account.create!
      5.times { User.create!(name: 'otel') }
    end

    it 'instruments SELECT queries' do
      User.where(name: 'otel').first

      select_spans = spans.select { |s| s.attributes['db.operation'].include?('User Load') }
      _(select_spans).wont_be_empty
    end

    it 'instruments UPDATE queries' do
      user = User.first
      user.update!(counter: 42)

      update_spans = spans.select { |s| s.attributes['db.operation'].include?('User Update') }
      _(update_spans).wont_be_empty
    end

    it 'instruments DELETE queries' do
      user = User.first
      user.destroy

      delete_spans = spans.select { |s| s.attributes['db.operation'].include?('User Destroy') }
      _(delete_spans).wont_be_empty
    end

    it 'instruments batch operations' do
      User.where(name: 'otel').delete_all

      delete_spans = spans.select { |s| s.attributes['db.operation'].include?('SQL') || s.attributes['db.operation'].include?('Delete') }
      _(delete_spans).wont_be_empty
    end
  end
end

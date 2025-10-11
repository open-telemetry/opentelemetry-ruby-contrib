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
  let(:spans) { exporter.finished_spans }

  before do
    # Capture original config before modification
    @original_config = instrumentation.config.dup

    OpenTelemetry::Instrumentation::ActiveRecord::Handlers.unsubscribe
    instrumentation.instance_variable_set(:@config, config)
    instrumentation.instance_variable_set(:@installed, false)

    instrumentation.install(config)
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

      # Filter to only sql.active_record spans
      sql_spans = spans.select { |s| s.name == 'User Create' }

      _(sql_spans).wont_be_empty
    end

    it 'records async attribute when query is async' do
      # Check if the connection supports concurrent connections and async executor is configur      # Create a user first so there's data to load
      User.create!(name: 'otel')

      exporter.reset

      # Trigger a real async query
      relations = [
        User.where(name: 'otel').load_async,
        User.where(name: 'not found').load_async,
        User.all.load_async
      ]

      # Now wait for completion
      result = relations.map(&:to_a)
      _(result).wont_be_empty

      # Find the User query span
      sql_spans = spans.select { |s| s.name.include?('User') }
      _(sql_spans).wont_be_nil

      # Skip if the query didn't run asynchronously (ActiveRecord may choose to run it synchronou
      # The query should have run asynchronously
      _(sql_spans.flat_map { |span| span.attributes['db.active_record.async'] }.compact.uniq).must_equal [true]
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

      cached_spans = spans.select { |s| s.attributes['db.active_record.cached'] == true }
      _(cached_spans).wont_be_empty
    end

    it 'does not add async attribute when not async' do
      User.first

      sql_spans = spans.select { |s| s.name.include?('User Load') }
      _(sql_spans).wont_be_empty

      sql_spans.each do |span|
        _(span.attributes.key?('db.active_record.async')).must_equal false
      end
    end

    it 'does not add cached attribute when not cached' do
      User.first

      sql_spans = spans.select { |s| s.name.include?('User Load') }
      _(sql_spans).wont_be_empty

      sql_spans.each do |span|
        _(span.attributes.key?('db.active_record.cached')).must_equal false
      end
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

      sql_spans = spans.reject { |s| s.name == 'ActiveRecord::Base.transaction' }
      _(sql_spans).wont_be_empty

      sql_spans.each do |span|
        _(span.kind).must_equal :internal
      end
    end

    it 'uses SQL as default name when name is not present' do
      # Manually trigger a notification without a name
      ActiveSupport::Notifications.instrument(
        'sql.active_record',
        sql: 'SELECT 1'
      )

      sql_span = spans.find { |s| s.name == 'SQL' }
      _(sql_span).wont_be_nil
    end

    it 'creates nested spans correctly' do
      Account.transaction do
        account = Account.create!
        User.create!(name: 'otel', account: account)
      end

      _(spans.any? { |s| s.name == 'ActiveRecord.transaction' }).must_equal true
      _(spans.any? { |s| s.name == 'Account Create' }).must_equal true
      _(spans.any? { |s| s.name == 'User Create' }).must_equal true

      # Verify parent-child relationships
      transaction_span = spans.find { |s| s.name == 'ActiveRecord.transaction' }
      create_spans = spans.select { |s| s.name.include?('Create') }

      create_spans.each do |span|
        _(span.trace_id).must_equal transaction_span.trace_id
      end
    end
  end

  describe 'with complex queries' do
    before do
      Account.create!
      5.times { User.create!(name: 'otel') }
    end

    it 'instruments SELECT queries' do
      User.where(name: 'otel').first

      select_spans = spans.select { |s| s.name.include?('User Load') }
      _(select_spans).wont_be_empty
    end

    it 'instruments UPDATE queries' do
      user = User.first
      user.update!(counter: 42)

      update_spans = spans.select { |s| s.name.include?('User Update') }
      _(update_spans).wont_be_empty
    end

    it 'instruments DELETE queries' do
      user = User.first
      user.destroy

      delete_spans = spans.select { |s| s.name.include?('User Destroy') }
      _(delete_spans).wont_be_empty
    end

    it 'instruments batch operations' do
      User.where(name: 'otel').delete_all

      delete_spans = spans.select { |s| s.name.include?('SQL') || s.name.include?('Delete') }
      _(delete_spans).wont_be_empty
    end
  end
end

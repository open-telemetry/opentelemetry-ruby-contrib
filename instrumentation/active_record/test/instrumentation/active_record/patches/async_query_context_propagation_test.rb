# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/active_record'
require_relative '../../../../lib/opentelemetry/instrumentation/active_record/patches/async_query_context_propagation'

ASYNC_TEST_LOGGER = Logger.new($stdout).tap { |logger| logger.level = Logger::WARN }

describe OpenTelemetry::Instrumentation::ActiveRecord::Patches::AsyncQueryContextPropagation do
  let(:exporter) { EXPORTER }
  let(:unfiltered_spans) { exporter.finished_spans }
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveRecord::Instrumentation.instance }
  let(:logger) { ASYNC_TEST_LOGGER }

  before do
    exporter.reset
    setup_asynchronous_queries_session
    User.create!
  end

  after do
    teardown_asynchronous_queries_session

    ActiveRecord::Base.subclasses.each do |model|
      model.connection.truncate(model.table_name)
    end
  end

  def setup_asynchronous_queries_session
    @_async_queries_session = ActiveRecord::Base.asynchronous_queries_tracker.start_session
  end

  def teardown_asynchronous_queries_session
    args = ActiveRecord::VERSION::MAJOR >= 8 ? [true] : []
    ActiveRecord::Base.asynchronous_queries_tracker.finalize_session(*args) if @_async_queries_session
  end

  def run_async_load
    logger.debug('>>> run async load')
    in_new_trace do
      OpenTelemetry::Context.with_value(SpanThreadIdTracking::TRACK_THREAD_ID, true) do
        instrumentation.tracer.in_span('test_wrapper') do
          if block_given?
            yield
          else
            users = User.all.load_async
            sleep(0.5)
            logger.debug('>>> async #to_a')
            users.to_a
          end
        end
      end
    end
  end

  def in_new_trace(&block)
    OpenTelemetry::Context.with_current(OpenTelemetry::Context::ROOT, &block)
  end

  def spans
    test_wrapper_span = unfiltered_spans.find { |span| span.name == 'test_wrapper' }
    unfiltered_spans.select { |span| span.trace_id == test_wrapper_span.trace_id }
  end

  def span_names
    spans.map(&:name).sort
  end

  # call with block_queue: true to completely block the executor (no tasks can be enqueued),
  # or with block_queue: false to block the workers only (tasks still accepted in the queue)
  def with_busy_executor(block_queue: true)
    _(ActiveRecord.async_query_executor).must_equal :global_thread_pool

    mutex = Mutex.new
    condvar = ConditionVariable.new
    executor = ActiveRecord.instance_variable_get(:@global_thread_pool_async_query_executor)

    task_count = executor.max_length
    task_count += executor.max_queue if block_queue

    awaiting_signals = (0...task_count).to_a

    # Fill up the max thread count and queue with tasks that
    # will never complete until they are signaled to do so.
    task_count.times do |n|
      executor.post do
        mutex.synchronize do
          ASYNC_TEST_LOGGER.debug("task #{n} waiting...")
          condvar.wait(mutex)
          ASYNC_TEST_LOGGER.debug("task #{n} got the signal")
          awaiting_signals.delete(n)
        end
      end
    end

    logger.debug("yielding... block_queue=#{block_queue}")
    yield
    logger.debug('...done!')
  ensure
    logger.debug('cleaning up...')
    # clean up the queue
    mutex.synchronize { condvar.signal } until awaiting_signals.empty?
  end

  def current_thread_id
    Thread.current.object_id
  end

  def execute_query_span
    spans.find { |span| span.name == 'User query' }
  end

  it 'async_query' do
    run_async_load

    _(span_names).must_equal(['test_wrapper', 'User query', 'schedule User query'].sort)
    _(execute_query_span.attributes['__test_only_thread_id']).wont_equal(current_thread_id)
    _(execute_query_span.attributes['async']).must_equal(true)
  end

  describe 'no executor' do
    before do
      @async_query_executor_was = ActiveRecord.async_query_executor
      ActiveRecord.async_query_executor = nil
    end

    after do
      ActiveRecord.async_query_executor = @async_query_executor_was
    end

    it 'is not actually async' do
      run_async_load # sic

      _(spans.map(&:name)).wont_include('Schedule User query')
      _(spans.map(&:name)).must_include('User query')

      user_query = spans.find { |span| span.name == 'User query' }
      _(user_query.attributes['async']).must_equal(false) if user_query.attributes.key?('async')
      _(span_names).must_equal(['User query', 'test_wrapper'].sort)
      _(execute_query_span.attributes['__test_only_thread_id']).must_equal(current_thread_id)
    end
  end

  it 'async_query_blocked_executor' do
    with_busy_executor { run_async_load }

    # In this case the wrapped task is executed as the 'fallback_action' by the thread pool executor,
    # so we get the async span, even though it is not actually async.
    _(execute_query_span.attributes['__test_only_thread_id']).must_equal(current_thread_id)

    skip(<<~SKIP)
      `async` _should_ be false here, but it's executed as a fallback action and
      is incorrectly set to `true`.

      Whether or not this is actually an issue is up for debate;
      it's true that the query would have been async if the global pool load was lower,
      so it could be said that the benefit of attempting to enqueue the task
      is measured in degrees, ranging from no benefit to saving the entire time of the query.

      However, the _other_ scenario in which the task is enqueued but not yet worked on
      causes `async` to be false.

      Ultimately, however, this is a bug in Rails's instrumentation around async queries,
      so it doesn't feel particularly pressing to solve it here with a bunch of
      otherwise unecessary patches.
    SKIP

    _(execute_query_span.attributes['async']).must_equal(false)
  end

  it 'async_query_slow_executor' do
    # executor accepts task, but doesn't fulfill it before the waiter
    with_busy_executor(block_queue: false) do
      run_async_load
    end

    # When #to_a is called, the query is still pending and hasn't been picked up,
    # so AR executes is synchronously. The executor task is cancelled (or should be?),
    # so this span won't be here.
    _(execute_query_span.attributes['async']).must_equal(false)
    _(execute_query_span.attributes['__test_only_thread_id']).must_equal(current_thread_id)
    _(span_names).must_equal(['User query', 'schedule User query', 'test_wrapper'])
  end

  it 'async_query_no_wait' do
    run_async_load do
      User.all.load_async.to_a
    end

    # here we call #to_a inline, so it (maybe) executes before the async scheduler
    # could assign the task to a worker. This expectation will not always pass,
    # but it remains here to exhaust the possible async execution scenarios.
    skip('this expectation is allowed to fail') if execute_query_span.attributes['async']

    _(execute_query_span.attributes['async']).must_equal(false)
    _(execute_query_span.attributes['__test_only_thread_id']).must_equal(current_thread_id)
  end

  it 'async_count' do
    if User.respond_to?(:async_count)
      run_async_load do
        count = User.async_count
        sleep(0.5)
        count.value
      end

      count_span = spans.find { |span| span.name == 'User Count' }
      _(count_span.attributes['async']).must_equal(true)
    else
      skip("async_count not supported in ActiveRecord #{ActiveRecord::VERSION::STRING}")
    end
  end

  it 'works with concurrent queries' do
    Account.create!

    run_async_load do
      users = User.all.load_async
      accounts = Account.all.load_async

      sleep(0.5)

      users.to_a
      accounts.to_a
    end

    user_schedule_span = spans.find { |span| span.name == 'schedule User query' }
    account_schedule_span = spans.find { |span| span.name == 'schedule Account query' }
    user_query_span = spans.find { |span| span.name == 'User query' }
    account_query_span = spans.find { |span| span.name == 'Account query' }
    test_wrapper_span = spans.find { |span| span.name == 'test_wrapper' }

    _(user_schedule_span.parent_span_id).must_equal(test_wrapper_span.span_id)
    _(account_schedule_span.parent_span_id).must_equal(test_wrapper_span.span_id)

    _(user_query_span.parent_span_id).must_equal(user_schedule_span.span_id)
    _(account_query_span.parent_span_id).must_equal(account_schedule_span.span_id)

    _(user_query_span.attributes['async']).must_equal(true)
    _(account_query_span.attributes['async']).must_equal(true)
  end
end

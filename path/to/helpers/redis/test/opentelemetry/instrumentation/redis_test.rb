# -*- coding: utf-8 -*-

require_relative 'test_helper'

class RedisTest < TestHelper
  def test_connect
    assert @redis.ping
  end

  def test_set_and_get
    @redis.set('foo', 'bar')
    assert_equal 'bar', @redis.get('foo')
  end

  def test_incr
    @redis.set('foo', 0)
    assert_equal 1, @redis.incr('foo')
    assert_equal 2, @redis.incr('foo')
  end

  def test_transaction
    @redis.multi do
      @redis.set('foo', 'bar')
      @redis.incr('foo')
    end
    assert_equal 2, @redis.get('foo')
  end
end
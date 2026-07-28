# -*- coding: utf-8 -*-

require 'minitest/autorun'
require_relative 'redis_test_helper'

class TestHelper < Minitest::Test
  def setup
    @redis = Redis.new
  end

  def teardown
    @redis.quit
  end
end
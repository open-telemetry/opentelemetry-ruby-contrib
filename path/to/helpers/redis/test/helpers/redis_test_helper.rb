# -*- coding: utf-8 -*-

module RedisTestHelper
  def redis
    @redis ||= Redis.new
  end
end
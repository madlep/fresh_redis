require 'fresh_redis/hash'
require 'fresh_redis/key'
require 'fresh_redis/string'
require 'fresh_redis/version'

class FreshRedis
  include Hash
  include String

  NIL_VALUE = "__FR_NIL__"

  def initialize(redis)
    @redis = redis
  end

  private
  def n(value)
    value || NIL_VALUE
  end

  def un_n(value)
    n?(value) ? nil : value
  end

  def n?(value)
    value == NIL_VALUE
  end
end

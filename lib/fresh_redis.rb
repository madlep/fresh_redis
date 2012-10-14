require 'fresh_redis/hash'
require 'fresh_redis/key'
require 'fresh_redis/string'
require 'fresh_redis/version'

class FreshRedis
  include Hash
  include String

  def initialize(redis)
    @redis = redis
  end
end

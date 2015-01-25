require 'fresh_redis/hash'
require 'fresh_redis/key'
require 'fresh_redis/set'
require 'fresh_redis/string'
require 'fresh_redis/version'

class FreshRedis
  include Hash
  include Set
  include String

  def initialize(redis, options={})
    @redis = redis
    @options = options
  end

  def build_key(base_key, options={})
    options = @options.merge(options)
    Key.build(base_key, options)
  end

end

require 'fresh_redis/timestamp'
require 'fresh_redis/version'
require 'fresh_redis/hash'
require 'fresh_redis/string'

class FreshRedis
  include Timestamp
  include Hash
  include String

  DEFAULT_OPTIONS = {
    :freshness => 60 * 60, # 1 hour
    :granularity => 1 * 60 # 1 minute
  }

  def initialize(redis)
    @redis = redis
  end

  def each_timestamped_key(key, t, freshness, granularity)
    @redis.pipelined {
      range_timestamps(t, freshness, granularity).each do |timestamp|
        timestamp_key = [key, timestamp].join(":")
        yield timestamp_key
      end
    }
  end

  private

  def default_options(options)
    options = DEFAULT_OPTIONS.merge(options)
    options[:t] ||= Time.now.to_i
    options
  end
end

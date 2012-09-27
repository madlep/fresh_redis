require 'fresh_redis/timestamp'
require 'fresh_redis/version'

class FreshRedis
  include Timestamp

  VERSION = "0.0.1"

  DEFAULT_OPTIONS = {
    :freshness => 60 * 60, # 1 hour
    :granularity => 1 * 60 # 1 minute
  }

  def initialize(redis)
    @redis = redis
  end

  def fincr(key, options={})
    options = default_options(options)
    t           = options[:t]
    freshness   = options[:freshness]
    granularity = options[:granularity]

    key = normalize_key(key, t, granularity)
    @redis.multi do
      @redis.incr key
      @redis.expire key, freshness
    end
  end

  def fsum(key, options={})
    options = default_options(options)

    reduce(key, options, 0){|acc, timestamp_total|
      acc + timestamp_total.to_i
    }
  end

  private
  def reduce(key, options={}, initial=nil, &reduce_operation)
    options = default_options(options)
    t           = options[:t]
    freshness   = options[:freshness]
    granularity = options[:granularity]

    raw_totals = @redis.pipelined {
      range_timestamps(t, freshness, granularity).each do |timestamp|
        timestamp_key = [key, timestamp].join(":")
        @redis.get(timestamp_key)
      end
    }

    raw_totals.reduce(initial, &reduce_operation)
  end

  def default_options(options)
    options = DEFAULT_OPTIONS.merge(options)
    options[:t] ||= Time.now.to_i
    options
  end
end

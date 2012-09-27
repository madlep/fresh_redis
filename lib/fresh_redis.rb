require 'fresh_redis/version'

class FreshRedis

  DEFAULTS = {
    :expiry => 60 * 60, # 1 hour
    :granularity => 1 * 60 # 1 minute
  }

  def initialize(redis)
    @redis = redis
  end

  def fincr(key, options={})
    options = DEFAULTS.merge(options)
    key = normalize_key(key, Time.now.to_i, options[:granularity])
    @redis.multi do
      redis.incr key
      redis.expire key, options[:expiry]
    end
  end

  def fsum(key, options={})
    reduce(key, options, 0){|acc, timestamp_total|
      acc + timestamp_total.to_i
    }
  end

  private
  def normalize_key(key, timestamp, granularity)
    [key, normalize_time(timestamp, granularity)].join(":")
  end

  def normalize_time(t, granularity)
    t - (t % granularity)
  end
  
  def range_timestamps(expiry, granularity)
    now = normalize_time(Time.now.to_i, granularity)
    start = normalize_time(now - expiry, granularity)
    (start..now).step(granularity)
  end

  def reduce(key, options={}, initial=nil, &reduce_operation)
    options = DEFAULTS.merge(options)
    totals = @redis.pipelined do
      range_timestamps(options[:expiry], options[:granularity]).each do |timestamp|
        timestamp_key = [key, timestamp].join(":")
        redis.get(timestamp_key)
      end
    end
    totals.reduce(initial, &reduce_operation)
  end
end

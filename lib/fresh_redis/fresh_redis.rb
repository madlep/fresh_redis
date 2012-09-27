class FreshRedis
  include Timestamp

  DEFAULT_OPTIONS = {
    :freshness => 60 * 60, # 1 hour
    :granularity => 1 * 60 # 1 minute
  }

  def initialize(redis)
    @redis = redis
  end

  def fincr(key, options={})
    options = DEFAULT_OPTIONS.merge(options)
    key = normalize_key(key, Time.now.to_i, options[:granularity])
    @redis.multi do
      @redis.incr key
      @redis.expire key, options[:freshness]
    end
  end

  def fsum(key, options={})
    options = DEFAULT_OPTIONS.merge(options)
    reduce(key, options, 0){|acc, timestamp_total|
      acc + timestamp_total.to_i
    }
  end

  private
  def reduce(key, options={}, initial=nil, &reduce_operation)
    options = DEFAULT_OPTIONS.merge(options)
    totals = @redis.pipelined do
      range_timestamps(options[:freshness], options[:granularity]).each do |timestamp|
        timestamp_key = [key, timestamp].join(":")
        @redis.get(timestamp_key)
      end
    end
    totals.reduce(initial, &reduce_operation)
  end
end

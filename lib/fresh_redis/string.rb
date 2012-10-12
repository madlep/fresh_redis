class FreshRedis
  module String
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

      raw_totals = each_timestamped_key(key, t, freshness, granularity) do |timestamp_key|
        @redis.get(timestamp_key)
      end

      raw_totals.reduce(initial, &reduce_operation)
    end
  end
end

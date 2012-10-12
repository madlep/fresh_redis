class FreshRedis
  module Hash
    def fhset(key, hash_key, value, options={})
      options = default_options(options)
      t           = options[:t]
      freshness   = options[:freshness]
      granularity = options[:granularity]

      key = normalize_key(key, t, granularity)
      @redis.multi do
        @redis.hset(key, hash_key, value)
        @redis.expire(key, freshness)
      end
    end

    def fhget(key, hash_key, options={})
      options = default_options(options)
      t           = options[:t]
      freshness   = options[:freshness]
      granularity = options[:granularity]

      each_timestamped_key(key, t, freshness, granularity) do |timestamp_key|
        @redis.hget(timestamp_key, hash_key)
      end.compact
    end

    def fhgetall(key, options={})
      options = default_options(options)
      t           = options[:t]
      freshness   = options[:freshness]
      granularity = options[:granularity]

      each_timestamped_key(key, t, freshness, granularity) do |timestamp_key|
        @redis.hgetall(timestamp_key)
      end.reject { |hash| hash.count.zero? }
    end

    def fhdel(key, hash_key, options={})
      options = default_options(options)
      t           = options[:t]
      freshness   = options[:freshness]
      granularity = options[:granularity]

      each_timestamped_key(key, t, freshness, granularity) do |timestamp_key|
        @redis.hdel(timestamp_key, hash_key)
      end
    end
  end
end

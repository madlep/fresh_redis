class FreshRedis
  module Hash
    def fhset(key, hash_key, value, options={})
      key = Key.build(key, options)
      @redis.multi do
        @redis.hset(key.redis_key, hash_key, value)
        @redis.expire(key.redis_key, key.freshness)
      end
    end

    def fhget(key, hash_key, options={})
      key = Key.build(key, options)
      @redis.pipelined {
        key.timestamp_buckets.each do |bucket_key|
          @redis.hget(bucket_key, hash_key)
        end
      }.compact
    end

    def fhgetall(key, options={})
      key = Key.build(key, options)
      @redis.pipelined {
        key.timestamp_buckets.each do |bucket_key|
          @redis.hgetall(bucket_key)
        end
      }.reject { |hash| hash.count.zero? }
    end

    def fhdel(key, hash_key, options={})
      key = Key.build(key, options)
      @redis.pipelined do
        key.timestamp_buckets.each do |bucket_key|
          @redis.hdel(bucket_key, hash_key)
        end
      end
    end
  end
end

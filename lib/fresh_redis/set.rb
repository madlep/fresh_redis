class FreshRedis
  module Set

    def fsadd(key, value, options={})
      key = build_key(key, options)
      @redis.multi do |transaction|
        transaction.sadd(key.redis_key, value)
        transaction.expire(key.redis_key, key.freshness)
      end
    end

    def fsmembers(key, options={})
      key = build_key(key, options)

      bucket_values = @redis.pipelined do |pipeline|
        key.timestamp_buckets.reverse.each do |bucket_key|
          pipeline.smembers(bucket_key)
        end
      end

      # find the first non-nil value
      bucket_values.flatten.uniq
    end

    def fsismembers(key, value, options={})
      key = build_key(key, options)

      bucket_values = @redis.pipelined do |pipeline|
        key.timestamp_buckets.reverse.each do |bucket_key|
          return true if pipeline.sismembers(bucket_key, value)
        end
      end

      # find the first non-nil value
      return false
    end

    def fsrem(key, value, options={})
      key = build_key(key, options)

      bucket_values = @redis.pipelined do |pipeline|
        key.timestamp_buckets.reverse.each do |bucket_key|
          pipeline.srem(bucket_key, value)
        end
      end
    end
  end
end

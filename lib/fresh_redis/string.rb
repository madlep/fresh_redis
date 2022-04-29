class FreshRedis
  module String
    def fincrby(key, increment, options={})
      key = build_key(key, options)
      @redis.multi do |transaction|
        transaction.incrby(key.redis_key, increment)
        transaction.expire(key.redis_key, key.freshness)
      end
    end

    def fincr(key, options={})
      fincrby(key, 1, options)
    end

    def fincrbyfloat(key, increment, options={})
      key = build_key(key, options)
      @redis.multi do |transaction|
        transaction.incrbyfloat(key.redis_key, increment)
        transaction.expire(key.redis_key, key.freshness)
      end
    end

    def fdecr(key, options={})
      fincrby(key, -1, options)
    end

    def fdecrby(key, decrement, options={})
      fincrby(key, -1 * decrement, options)
    end

    def fsum(key, options={})
      key = build_key(key, options)
      @redis.pipelined { |pipeline|
        key.timestamp_buckets.each do |bucket_key|
          pipeline.get(bucket_key)
        end
      }.reduce(0){|acc, value|
        value ? acc + value.to_f : acc
      }
    end
  end
end

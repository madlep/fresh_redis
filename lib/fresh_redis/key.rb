require 'fresh_redis/timestamp'

class FreshRedis
  class Key
    include Timestamp

    DEFAULT_OPTIONS = {
      :freshness => 60 * 60, # 1 hour
      :granularity => 1 * 60 # 1 minute
    }

    def self.build(*args)
      raise "Don't know how to build FreshRedis::Key for #{args.inspect}" unless args[0]

      return args[0] if Key === args[0] # early exit if we've already got a key

      base_key = args[0]
        
      options = DEFAULT_OPTIONS.merge(args[1] || {})
      options[:t] ||= Time.now.to_i

      self.new(base_key, options[:t], options[:freshness], options[:granularity])
    end
    
    attr_reader :freshness

    def initialize(base_key, t, freshness, granularity)
      @base_key     = base_key
      @t            = t
      @freshness    = freshness
      @granularity  = granularity
    end

    def redis_key
      normalize_key(@base_key, @t, @granularity)
    end

    def timestamp_buckets
      from = normalize_time(@t - @freshness, @granularity)
      to = normalize_time(@t, @granularity)
      (from..to).step(@granularity).map{|timestamp| [@base_key, timestamp].join(":") }
    end

    private
    def normalize_key(key, t, granularity)
      [key, normalize_time(t, granularity)].join(":")
    end
  end
end

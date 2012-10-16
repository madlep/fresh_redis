class FreshRedis
  class Key
    # TODO remove concept of time from a key. Just be about redis key, freshness, granularity

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
      [@base_key, normalize_time(@t, @granularity)].join(":")
    end

    def timestamp_buckets
      from = normalize_time(@t - @freshness, @granularity)
      to = normalize_time(@t, @granularity)
      (from..to).step(@granularity).map{|timestamp| [@base_key, timestamp].join(":") }
    end

    def ==(other)
      same = true
      same &= Key === other
      same &= @base_key     == other.instance_variable_get(:@base_key)
      same &= @t            == other.instance_variable_get(:@t)
      same &= @freshness    == other.instance_variable_get(:@freshness)
      same &= @granularity  == other.instance_variable_get(:@granularity)
      same
    end

    private
    def normalize_time(t, granularity)
      t - (t % granularity)
    end
  end
end

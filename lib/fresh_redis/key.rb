require 'time'

class FreshRedis
  class Key

    DEFAULT_OPTIONS = {
      :freshness => 60 * 60, # 1 hour
      :granularity => 1 * 60 # 1 minute
    }

    def self.build(*args)
      raise "Don't know how to build FreshRedis::Key for #{args.inspect}" unless args[0]

      return args[0] if Key === args[0] # early exit if we've already got a key

      base_key = args[0]
        
      options = DEFAULT_OPTIONS.merge(args[1] || {})

      self.new(base_key, options[:freshness], options[:granularity])
    end
    
    attr_reader :freshness

    def initialize(base_key, freshness, granularity)
      @base_key     = base_key
      @freshness    = freshness
      @granularity  = granularity
    end

    def redis_key
      [@base_key, normalize_time(Time.now.to_i, @granularity)].join(":")
    end

    def timestamp_buckets
      t = Time.now.to_i

      from = normalize_time(t - @freshness, @granularity)
      to = normalize_time(t, @granularity)
      (from..to).step(@granularity).map{|timestamp| [@base_key, timestamp.to_i].join(":") }
    end

    def ==(other)
      same = true
      same &= Key === other
      same &= @base_key     == other.instance_variable_get(:@base_key)
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

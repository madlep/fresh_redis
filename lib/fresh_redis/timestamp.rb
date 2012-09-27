class FreshRedis
  module Timestamp
    def normalize_key(key, t, granularity)
      [key, normalize_time(t, granularity)].join(":")
    end

    def normalize_time(t, granularity)
      t - (t % granularity)
    end

    def range_timestamps(t, freshness, granularity)
      from = normalize_time(t - freshness, granularity)
      to = normalize_time(t, granularity)
      (from..to).step(granularity)
    end
  end
end

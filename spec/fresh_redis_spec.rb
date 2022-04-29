# frozen_string_literal: true

require "fresh_redis"
require "mock_redis"

describe FreshRedis do
  let(:mock_redis) { MockRedis.new }

  describe "#build_key" do
    it "builds a new key based on custom options" do
      key = "key"
      expect(FreshRedis::Key).to receive(:build).with("foo",
                                                      hash_including(granularity: 111, freshness: 222))
                                                .and_return(key)

      fresh_redis = FreshRedis.new(mock_redis, granularity: 111, freshness: 222)

      expect(fresh_redis.build_key("foo")).to eq key
    end

    it "builds a new key no options if custom options not provided" do
      key = "key"
      FreshRedis::Key.should_receive(:build).with("foo", {}).and_return(key)

      fresh_redis = FreshRedis.new(mock_redis)

      expect(fresh_redis.build_key("foo")).to eq key
    end
  end
end

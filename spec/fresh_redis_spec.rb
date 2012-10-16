require 'fresh_redis'
require 'mock_redis'

describe FreshRedis do
  let(:mock_redis) { MockRedis.new }

  describe "#build_key" do
    it "builds a new key based on custom options" do
      key = "key"
      FreshRedis::Key.should_receive(:build).with("foo", :granularity => 111, :freshness => 222).and_return(key)

      fresh_redis = FreshRedis.new(mock_redis, :granularity => 111, :freshness => 222)

      fresh_redis.build_key("foo").should == key
    end

    it "builds a new key no options if custom options not provided" do
      key = "key"
      FreshRedis::Key.should_receive(:build).with("foo", {}).and_return(key)

      fresh_redis = FreshRedis.new(mock_redis)

      fresh_redis.build_key("foo").should == key
    end

  end
end

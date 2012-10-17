require 'fresh_redis'
require 'timecop'

describe FreshRedis::Key do
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00") }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00") }

  before(:each) { Timecop.travel(now) }
  after(:each) { Timecop.return }

  describe ".build" do
    it "complains if no args" do
      expect { FreshRedis::Key.build() }.to raise_error
    end

    it "just returns the key if a FreshRedis::Key is provided" do
      key = FreshRedis::Key.new("key", 123, 456)
      FreshRedis::Key.build(key).should == key
    end

    it "constructs a FreshRedis::Key with the provided options" do
      key = FreshRedis::Key.build("key", :freshness => 123, :granularity => 456)
      key.should == FreshRedis::Key.new("key", 123, 456)
    end

        
    it "constructs a FreshRedis::Key with the default options" do
      key = FreshRedis::Key.build("key")
      key.should == FreshRedis::Key.new(
        "key", 
        FreshRedis::Key::DEFAULT_OPTIONS[:freshness], 
        FreshRedis::Key::DEFAULT_OPTIONS[:granularity]
      )
    end

  end

  describe "#redis_key" do
    it "should append the normalized timestamp to the key" do
      FreshRedis::Key.build("foo", :granularity => 60).redis_key.should == "foo:#{normalized_now_minute.to_i}"
    end
  end
  
  describe "#timestamp_buckets" do
    let(:buckets) { FreshRedis::Key.build("foo", :freshness => 600, :granularity => 60).timestamp_buckets }
    it "generates an enumerable over the range" do
      buckets.should be_kind_of(Enumerable)
    end

    it "has one timestamp bucket for each granularity step in the fresh range" do
      buckets.count.should == 11 # fence-posting. we include the first and last elements in a timestamp range split by granularity
    end

    it "has the first timestamp as the maximum freshness" do
      buckets.first.should == ["foo", normalized_now_minute.to_i - 600].join(":")
    end

    it "has now as the maximum freshness" do
      buckets.to_a.last.should == ["foo", normalized_now_minute.to_i].join(":")
    end

    it "steps through the normalized timestamps split up by granularity" do
      buckets.each_with_index{|b, i| b.should == ["foo", normalized_now_minute.to_i - 600 + i * 60].join(":") }
    end
  end
end

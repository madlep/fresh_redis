require 'fresh_redis'

describe FreshRedis::Timestamp do
  subject { Class.new.extend(FreshRedis::Timestamp) }
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00").to_i }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00").to_i }
  let(:normalized_now_hour) { Time.new(2012, 9, 27, 15, 0, 0, "+10:00").to_i }

  describe "#normalize_key" do
    it "should append the normalized timestamp to the key" do
      subject.normalize_key("foo", now, 60).should == "foo:#{normalized_now_minute}"
    end
  end
  
  describe "#normalize_time" do
    it "should round down timestamp to nearest multiple of granularity" do
      subject.normalize_time(now, 60).should == normalized_now_minute
      subject.normalize_time(now, 3600).should == normalized_now_hour
    end

    it "shouldn't change the timestamp if the granularity is 1" do
      subject.normalize_time(now, 1).should == now
    end
  end

  describe "#range_timestamps" do
    let(:range) { subject.range_timestamps(now, 600, 60) }
    it "should generate an enumerable over the range" do
      range.should be_kind_of(Enumerable)
    end

    it "should have one timestamp for each granularity step in the fresh range" do
      range.count.should == 11 # fence-posting. we include the first and last elements in a timestamp range split by granularity
    end

    it "should have the first timestamp as the maximum freshness" do
      range.first.should == normalized_now_minute - 600
    end

    it "should have now as the maximum freshness" do
      range.to_a.last.should == normalized_now_minute
    end

    it "should step through the normalized timestamps split up by granularity" do
      range.each_with_index{|t, i| t.should == normalized_now_minute - 600 + i * 60 }
    end
  end

end

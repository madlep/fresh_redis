require 'fresh_redis'
require 'mock_redis'

describe FreshRedis do
  subject{ FreshRedis.new(mock_redis) }
  let(:mock_redis) { MockRedis.new }
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00").to_i }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00").to_i }

  describe "#fincr" do
    it "should increment the key for the normalized timestamp" do
      subject.fincr "foo", :granularity => 60, :t => now
      subject.fincr "foo", :granularity => 60, :t => now + 3
      subject.fincr "foo", :granularity => 60, :t => now + 60 # different normalized key
      mock_redis.data["foo:#{normalized_now_minute}"].to_i.should == 2
    end

    it "should set the freshness as the expiry" do
      # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
      subject.fincr "foo", :freshness => 3600, :t => now
      mock_redis.ttl("foo:#{normalized_now_minute}").should == 3600
    end
  end

  describe "#fsum" do
    it "should add the values of keys for specified freshness and granularity" do
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 - 10
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 1
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 2
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 3
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 5
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 8
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 13
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 21
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 34
      subject.fincr "foo", :freshness => 60, :granularity => 10, :t => now - 60 + 55

      subject.fsum("foo", :freshness => 60, :granularity => 10, :t => now).should ==  9
    end
  end

  describe "#fhset" do
    it "should set a value for a key in a hash for the normalized timestamp" do
      subject.fhset "foo", "bar", "value", :granularity => 60, :t => now
      subject.fhset "foo", "bar", "newer_value", :granularity => 60, :t => now + 3
      subject.fhset "foo", "bar", "different_bucket", :granularity => 60, :t => now + 60 # different normalized key
      mock_redis.data["foo:#{normalized_now_minute}"].should == {"bar" => "newer_value"}
    end

    it "should set the freshness as the expiry" do
      # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
      subject.fhset "foo", "bar", "baz", :freshness => 3600, :t => now
      mock_redis.ttl("foo:#{normalized_now_minute}").should == 3600
    end
  end

  describe "#fhdel" do
    it "should remove a value for a key in a hash for the normalized timestamp" do
      subject.fhset "foo", "bar", "value", :granularity => 10, :freshness => 20, :t => now - 15
      subject.fhset "foo", "bar", "different_bucket", :granularity => 10, :freshness => 20, :t => now
      subject.fhdel "foo", "bar", :granularity => 10, :freshness => 0, :t => now # Should only delete the most recent bucket
      subject.fhget("foo", "bar", :granularity => 10, :freshness => 20, :t => now ).should == ["value"]
    end
  end

  describe "#fhget" do
    it "should get all the values of the specified key in specified hash for specified frenhness and granularity" do
      subject.fhset "requests", "some_key", "0", :freshness => 60, :granularity => 10, :t => now - 60 - 10 # Too old of a bucket
      subject.fhset "requests", "some_key", "1", :freshness => 60, :granularity => 10, :t => now - 60 + 5
      subject.fhset "requests", "some_key", "2", :freshness => 60, :granularity => 10, :t => now - 60 + 15
      subject.fhset "requests", "some_key", "3", :freshness => 60, :granularity => 10, :t => now - 60 + 16 # This overwrites the previous value in the bucket
      subject.fhget("requests", "some_key", :freshness => 60, :granularity => 10, :t => now).should == ["1", "3"]
    end
  end
end

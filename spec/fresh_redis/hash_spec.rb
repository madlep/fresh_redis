require 'fresh_redis'
require 'mock_redis'

describe FreshRedis do
  subject{ FreshRedis.new(mock_redis) }
  let(:mock_redis) { MockRedis.new }
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00").to_i }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00").to_i }
  let(:normalized_one_minute_ago) { Time.new(2012, 9, 27, 15, 39, 0, "+10:00").to_i }
  let(:normalized_two_minutes_ago) { Time.new(2012, 9, 27, 15, 38, 0, "+10:00").to_i }
  let(:normalized_old) { Time.new(2012, 9, 27, 14, 38, 0, "+10:00").to_i } 

  context "hash keys" do 

    describe "#fhset" do
      it "sets a value for a key in a hash for the normalized timestamp" do
        subject.fhset "foo", "bar", "value", :t => now - 3
        subject.fhset "foo", "bar", "newer_value", :t => now
        subject.fhset "foo", "bar", "different_bucket", :t => now - 60 # different normalized key

        mock_redis.data["foo:#{normalized_now_minute}"].should == {"bar" => "newer_value"}
      end

      it "sets a nil value ok" do
        subject.fhset "foo", "bar", nil, :t => now

        mock_redis.data["foo:#{normalized_now_minute}"].should == {"bar" => "" }
      end

      it "sets the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fhset "foo", "bar", "baz", :freshness => 3600, :t => now

        mock_redis.ttl("foo:#{normalized_now_minute}").should == 3600
      end
    end

    describe "#fhdel" do
      it "removes the field from all timestamp buckets" do
        subject.fhset "foo", "bar", "value", :t => now
        subject.fhset "foo", "baz", "don't touch", :t => now
        subject.fhset "foo", "bar", "different_bucket", :t => now - 60
        subject.fhset "foo", "baz", "I shouldn't be returned", :t => now - 60

        subject.fhdel "foo", "bar", :t => now # Should only change the most recent bucket

        mock_redis.data["foo:#{normalized_now_minute}"].should == {"baz" => "don't touch"}
        mock_redis.data["foo:#{normalized_one_minute_ago}"].should == {"baz" => "I shouldn't be returned"}
      end
    end

    describe "#fhget" do
      it "gets the most recent value for the field across timestamped buckets" do
        mock_redis.hset "foo:#{normalized_now_minute}", "notbar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", "bill"
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "bar", "louis"

        subject.fhget("foo", "bar", :t => now).should == "bill"
      end

      it "returns nil if value is not found" do
        subject.fhget("foo", "bar", :t => now).should be_nil
      end

      it "returns nil if the value is in a bucket that has expired" do
        # this should be handled by redis expiry anyway, but verify code is behaving as expected and not querying more data than needed
        mock_redis.hset "foo:#{normalized_old}", "bar", "louis"
        subject.fhget("foo", "bar", :t => now).should be_nil
      end
    end

    describe "#fhgetall" do
      it "merges the values for all keys across timestamp buckets" do
        mock_redis.hset "foo:#{normalized_now_minute}", "bar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "baz", "zoey"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", "I shouldn't be returned"
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "boz", "louis"

        subject.fhgetall("foo", :t => now).should == { "bar" => "francis", "baz" => "zoey", "boz" => "louis" }
      end
    end
  end

end

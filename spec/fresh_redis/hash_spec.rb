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
        subject.fhset "foo", "bar", "value", :granularity => 60, :t => now - 3
        subject.fhset "foo", "bar", "newer_value", :granularity => 60, :t => now
        subject.fhset "foo", "bar", "different_bucket", :granularity => 60, :t => now - 60 # different normalized key

        mock_redis.data["foo:#{normalized_now_minute}"].should == {"bar" => "newer_value"}
      end

      it "sets a placeholder value if nil is set as the value" do
        subject.fhset "foo", "bar", nil, :granularity => 60, :t => now

        mock_redis.data["foo:#{normalized_now_minute}"].should == {"bar" => FreshRedis::NIL_VALUE }
      end

      it "sets the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fhset "foo", "bar", "baz", :freshness => 3600, :t => now

        mock_redis.ttl("foo:#{normalized_now_minute}").should == 3600
      end
    end

    describe "#fhdel" do
      it "sets the value for a key in a hash for the normalized timestamp to be placeholder nil" do
        subject.fhset "foo", "bar", "value", :granularity => 60, :t => now
        subject.fhset "foo", "bar", "different_bucket", :granularity => 60, :t => now - 60

        subject.fhdel "foo", "bar", :granularity => 60, :t => now # Should only change the most recent bucket

        mock_redis.data["foo:#{normalized_now_minute}"].should == { "bar" => FreshRedis::NIL_VALUE }
        mock_redis.data["foo:#{normalized_one_minute_ago}"].should == { "bar" => "different_bucket" }
      end
    end

    describe "#fhget" do
      it "gets the most recent value for the field across timestamped buckets" do
        mock_redis.hset "foo:#{normalized_now_minute}", "notbar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", "bill"
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "bar", "louis"

        subject.fhget("foo", "bar", :granularity => 60, :t => now).should == "bill"
      end

      it "returns nil if the most recent value is the nil placeholder" do
        mock_redis.hset "foo:#{normalized_now_minute}", "notbar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", FreshRedis::NIL_VALUE
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "bar", "louis"

        subject.fhget("foo", "bar", :granularity => 60, :t => now).should be_nil
      end

      it "returns the most recent value if a nil placeholder value in an earlier bucket has been overwritten in a later bucket" do
        mock_redis.hset "foo:#{normalized_now_minute}", "bar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", FreshRedis::NIL_VALUE
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "bar", "louis"

        subject.fhget("foo", "bar", :granularity => 60, :t => now).should == "francis"
      end

      it "returns nil if value is not found" do
        subject.fhget("foo", "bar", :granularity => 60, :t => now).should be_nil
      end

      it "returns nil if the value is in a bucket that has expired" do
        # this should be handled by redis expiry anyway, but verify code is behaving as expected and not querying more data than needed
        mock_redis.hset "foo:#{normalized_old}", "bar", "louis"
        subject.fhget("foo", "bar", :granularity => 60, :t => now).should be_nil
      end
    end

    describe "#fhgetall" do
      it "merges the values for all keys across timestamp buckets" do
        mock_redis.hset "foo:#{normalized_now_minute}", "bar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "baz", "zoey"
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "boz", "louis"

        subject.fhgetall("foo", :granularity => 60, :t => now).should == { "bar" => "francis", "baz" => "zoey", "boz" => "louis" }
      end

      it "removes keys that have a nil placeholder value as the most recent value" do
        mock_redis.hset "foo:#{normalized_now_minute}", "bar", FreshRedis::NIL_VALUE
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", "zoey"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "baz", "louis"

        subject.fhgetall("foo", :granularity => 60, :t => now).should == { "baz" => "louis" }
      end

      it "returns the most recent value if a nil placeholder value in an earlier bucket has been overwritten in a later bucket" do
        mock_redis.hset "foo:#{normalized_now_minute}", "bar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "bar", FreshRedis::NIL_VALUE
        mock_redis.hset "foo:#{normalized_two_minutes_ago}", "bar", "louis"
        mock_redis.hset "foo:#{normalized_one_minute_ago}", "baz", "bill"

        subject.fhgetall("foo", :granularity => 60, :t => now).should == { "bar" => "francis", "baz" => "bill" }
      end
    end
  end

end

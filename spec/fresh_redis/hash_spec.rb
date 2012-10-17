require 'fresh_redis'
require 'mock_redis'
require 'timecop'

describe FreshRedis do
  subject{ FreshRedis.new(mock_redis) }
  let!(:mock_redis) { MockRedis.new }
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00") }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00") }
  let(:normalized_one_minute_ago) { Time.new(2012, 9, 27, 15, 39, 0, "+10:00") }
  let(:normalized_two_minutes_ago) { Time.new(2012, 9, 27, 15, 38, 0, "+10:00") }
  let(:normalized_old) { Time.new(2012, 9, 27, 14, 38, 0, "+10:00") } 

  context "hash keys" do 
    before(:each) { Timecop.travel(now) }
    after(:each) { Timecop.return }

    describe "#fhset" do
      it "sets a value for a key in a hash for the normalized timestamp" do
        Timecop.freeze(now - 3)   { subject.fhset "foo", "bar", "value" }
        Timecop.freeze(now)       { subject.fhset "foo", "bar", "newer_value" }
        Timecop.freeze(now - 60)  { subject.fhset "foo", "bar", "different_bucket" } # different normalized key

        mock_redis.data["foo:#{normalized_now_minute.to_i}"].should == {"bar" => "newer_value"}
      end

      it "sets a nil value ok" do
        Timecop.freeze(now) { subject.fhset "foo", "bar", nil }

        mock_redis.data["foo:#{normalized_now_minute.to_i}"].should == {"bar" => "" }
      end

      it "sets the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fhset "foo", "bar", "baz", :freshness => 3600

        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fhdel" do
      it "removes the field from all timestamp buckets" do
        Timecop.travel(now)       { subject.fhset "foo", "bar", "value" }
        Timecop.travel(now)       { subject.fhset "foo", "baz", "don't touch" }
        Timecop.travel(now - 60)  { subject.fhset "foo", "bar", "different_bucket" }
        Timecop.travel(now - 60)  { subject.fhset "foo", "baz", "I shouldn't be returned" }

        Timecop.travel(now)       { subject.fhdel "foo", "bar" } # Should only change the most recent bucket

        mock_redis.data["foo:#{normalized_now_minute.to_i}"].should == {"baz" => "don't touch"}
        mock_redis.data["foo:#{normalized_one_minute_ago.to_i}"].should == {"baz" => "I shouldn't be returned"}
      end
    end

    describe "#fhget" do
      it "gets the most recent value for the field across timestamped buckets" do
        mock_redis.hset "foo:#{normalized_now_minute.to_i}", "notbar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago.to_i}", "bar", "bill"
        mock_redis.hset "foo:#{normalized_two_minutes_ago.to_i}", "bar", "louis"

        subject.fhget("foo", "bar").should == "bill"
      end

      it "returns nil if value is not found" do
        subject.fhget("foo", "bar").should be_nil
      end

      it "returns nil if the value is in a bucket that has expired" do
        # this should be handled by redis expiry anyway, but verify code is behaving as expected and not querying more data than needed
        mock_redis.hset "foo:#{normalized_old.to_i}", "bar", "louis"
        subject.fhget("foo", "bar").should be_nil
      end
    end

    describe "#fhgetall" do
      it "merges the values for all keys across timestamp buckets" do
        mock_redis.hset "foo:#{normalized_now_minute.to_i}", "bar", "francis"
        mock_redis.hset "foo:#{normalized_one_minute_ago.to_i}", "baz", "zoey"
        mock_redis.hset "foo:#{normalized_one_minute_ago.to_i}", "bar", "I shouldn't be returned"
        mock_redis.hset "foo:#{normalized_two_minutes_ago.to_i}", "boz", "louis"

        subject.fhgetall("foo").should == { "bar" => "francis", "baz" => "zoey", "boz" => "louis" }
      end
    end
  end

end

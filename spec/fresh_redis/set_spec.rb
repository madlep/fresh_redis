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

  context "sets" do 
    before(:each) { Timecop.travel(now) }
    after(:each) { Timecop.return }

    describe "#fsadd" do
      it "sets a value in a set for the normalized timestamp" do
        Timecop.freeze(now - 3)   { subject.fsadd "foo", "value" }
        Timecop.freeze(now)       { subject.fsadd "foo", "newer_value" }
        Timecop.freeze(now - 60)  { subject.fsadd "foo", "different_bucket" } # different normalized key

        mock_redis.smembers("foo:#{normalized_now_minute.to_i}").should == ['newer_value', 'value']
      end

      it "sets a nil value ok" do
        Timecop.freeze(now) { subject.fsadd "foo", nil }

        mock_redis.smembers("foo:#{normalized_now_minute.to_i}").should == ['']
      end

      it "sets the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fsadd "foo", "baz", :freshness => 3600

        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fsrem" do
      it "removes the field from all timestamp buckets" do
        Timecop.travel(now)       { subject.fsadd "foo", "value" }
        Timecop.travel(now)       { subject.fsadd "foo", "don't touch" }
        Timecop.travel(now - 60)  { subject.fsadd "foo", "value" }
        Timecop.travel(now - 60)  { subject.fsadd "foo", "different_bucket" }
        Timecop.travel(now - 60)  { subject.fsadd "foo", "I shouldn't be returned" }

        Timecop.travel(now)       { subject.fsrem "foo", "value" } # Should only change the most recent bucket

        mock_redis.smembers("foo:#{normalized_now_minute.to_i}").should == ["don't touch"]
        mock_redis.smembers("foo:#{normalized_one_minute_ago.to_i}").should == ["I shouldn't be returned", "different_bucket"]
      end
    end

    describe "#fsmembers" do
      it "gets the union of all members for the fields across timestamped buckets" do
        mock_redis.sadd "foo:#{normalized_now_minute.to_i}", "notbar"
        mock_redis.sadd "foo:#{normalized_one_minute_ago.to_i}", "bar"
        mock_redis.sadd "foo:#{normalized_two_minutes_ago.to_i}", "bar"

        subject.fsmembers("foo").should == ['notbar', 'bar']
      end
    end
  end

end

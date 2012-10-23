require 'fresh_redis'
require 'mock_redis'
require 'timecop'

describe FreshRedis do
  subject{ FreshRedis.new(mock_redis) }
  let(:mock_redis) { MockRedis.new }
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00") }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00") }
  let(:normalized_one_minute_ago) { Time.new(2012, 9, 27, 15, 39, 0, "+10:00") }

  before(:each) { Timecop.travel(now) }
  after(:each) { Timecop.return }

  context "string keys" do
    describe "#fincr" do
      it "should increment the key for the normalized timestamp" do
        Timecop.freeze(now)       { subject.fincr "foo" }
        Timecop.freeze(now + 3)   { subject.fincr "foo" }
        Timecop.freeze(now - 60)  { subject.fincr "foo" } # different normalized key
        mock_redis.data["foo:#{normalized_now_minute.to_i}"].to_i.should == 2
        mock_redis.data["foo:#{normalized_one_minute_ago.to_i}"].to_i.should == 1
      end

      it "should set the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fincr "foo", :freshness => 3600
        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fincrby" do
      it "should increment the key for the normalized timestamp by the specified amount" do
        Timecop.freeze(now)       { subject.fincrby "foo", 2 } 
        Timecop.freeze(now + 3)   { subject.fincrby "foo", 3 }
        Timecop.freeze(now - 60)  { subject.fincrby "foo", 4 } # different normalized key
        mock_redis.data["foo:#{normalized_now_minute.to_i}"].to_i.should == 5
        mock_redis.data["foo:#{normalized_one_minute_ago.to_i}"].to_i.should == 4
      end

      it "should set the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fincrby "foo", 5, :freshness => 3600
        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fdecr" do
      it "should decrement the key for the normalized timestamp" do
        Timecop.freeze(now)       { subject.fdecr "foo" }
        Timecop.freeze(now + 3)   { subject.fdecr "foo" }
        Timecop.freeze(now - 60)  { subject.fdecr "foo" } # different normalized key
        mock_redis.data["foo:#{normalized_now_minute.to_i}"].to_i.should == -2
        mock_redis.data["foo:#{normalized_one_minute_ago.to_i}"].to_i.should == -1
      end

      it "should set the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fdecr "foo", :freshness => 3600
        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fdecrby" do
      it "should decrement the key for the normalized timestamp by the specified amount" do
        Timecop.freeze(now)       { subject.fdecrby "foo", 2 } 
        Timecop.freeze(now + 3)   { subject.fdecrby "foo", 3 }
        Timecop.freeze(now - 60)  { subject.fdecrby "foo", 4 } # different normalized key
        mock_redis.data["foo:#{normalized_now_minute.to_i}"].to_i.should == -5
        mock_redis.data["foo:#{normalized_one_minute_ago.to_i}"].to_i.should == -4
      end

      it "should set the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fdecrby "foo", 5, :freshness => 3600
        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fsum" do
      it "should add the values of keys for specified freshness and granularity" do
        mock_redis.set("foo:#{normalized_now_minute.to_i}", "7")
        mock_redis.set("foo:#{normalized_one_minute_ago.to_i}", "-2")
        subject.fsum("foo").should ==  5
      end
    end

  end
end

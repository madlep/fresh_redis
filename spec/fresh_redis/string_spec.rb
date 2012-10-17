require 'fresh_redis'
require 'mock_redis'
require 'timecop'

describe FreshRedis do
  subject{ FreshRedis.new(mock_redis) }
  let(:mock_redis) { MockRedis.new }
  let(:now) { Time.new(2012, 9, 27, 15, 40, 56, "+10:00") }
  let(:normalized_now_minute) { Time.new(2012, 9, 27, 15, 40, 0, "+10:00") }

  before(:each) { Timecop.travel(now) }
  after(:each) { Timecop.return }

  context "string keys" do
    describe "#fincr" do
      it "should increment the key for the normalized timestamp" do
        Timecop.freeze(now)       { subject.fincr "foo" }
        Timecop.freeze(now + 3)   { subject.fincr "foo" }
        Timecop.freeze(now + 60)  { subject.fincr "foo" } # different normalized key
        mock_redis.data["foo:#{normalized_now_minute.to_i}"].to_i.should == 2
      end

      it "should set the freshness as the expiry" do
        # relying on mock_redis's time handling here - which converts to/from using Time.now Possible flakey temporal breakage potential
        subject.fincr "foo", :freshness => 3600
        mock_redis.ttl("foo:#{normalized_now_minute.to_i}").should == 3600
      end
    end

    describe "#fsum" do
      subject{ FreshRedis.new(mock_redis, :granularity => 10, :freshness => 60) }
      it "should add the values of keys for specified freshness and granularity" do
        Timecop.freeze(now - 60 - 10) { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 1)  { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 2)  { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 3)  { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 5)  { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 8)  { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 13) { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 21) { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 34) { subject.fincr "foo" }
        Timecop.freeze(now - 60 + 55) { subject.fincr "foo" }

        subject.fsum("foo").should ==  9
      end
    end

  end
end

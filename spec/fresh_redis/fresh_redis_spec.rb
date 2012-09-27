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
end

require "../spec_helper"

describe Flux::LineProtocol do
  describe ".serialize" do
    time = Time.utc
    ts = time.to_unix

    it "serializes a simple point to line protocol" do
      point = Flux::DataPoint.new "foo", time, a: 1
      Flux::LineProtocol.serialize(point).should eq("foo a=1 #{ts}")
    end

    it "serializes a multi-field point to line protocol" do
      point = Flux::DataPoint.new "foo", time, a: 1, b: true
      Flux::LineProtocol.serialize(point).should eq("foo a=1,b=t #{ts}")
    end

    it "serializes when tags are present" do
      point = Flux::DataPoint.new "foo", time, a: 1
      point.tag :test, "bar"
      Flux::LineProtocol.serialize(point).should eq("foo,test=bar a=1 #{ts}")
    end
  end
end

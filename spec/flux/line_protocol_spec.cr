require "../spec_helper"

describe Flux::LineProtocol do
  describe ".serialize" do
    time = Time.utc(2009, 2, 13, 23, 31, 30)
    ts = "1234567890000000000"

    it "serializes integers" do
      point = Flux::Point.new "foo", time, a: 1_i64
      Flux::LineProtocol.serialize(point).should eq("foo a=1i #{ts}")
    end

    it "serializes unsigned integers" do
      point = Flux::Point.new "foo", time, a: 1_u64
      Flux::LineProtocol.serialize(point).should eq("foo a=1u #{ts}")
    end

    it "serializes floats" do
      point = Flux::Point.new "foo", time, a: 1.0
      Flux::LineProtocol.serialize(point).should eq("foo a=1.0 #{ts}")
    end

    it "serializes booleans" do
      point = Flux::Point.new "foo", time, a: true
      Flux::LineProtocol.serialize(point).should eq("foo a=t #{ts}")
      point2 = Flux::Point.new "foo", time, a: false
      Flux::LineProtocol.serialize(point2).should eq("foo a=f #{ts}")
    end

    it "serializes strings" do
      point = Flux::Point.new "foo", time, a: "bar"
      Flux::LineProtocol.serialize(point).should eq("foo a=\"bar\" #{ts}")
    end

    it "serializes a multi-field points" do
      point = Flux::Point.new "foo", time, a: 1_i64, b: true
      Flux::LineProtocol.serialize(point).should eq("foo a=1i,b=t #{ts}")
    end

    it "serializes when tags are present" do
      point = Flux::Point.new "foo", time, a: 1_i64
      point.tag test: "bar"
      Flux::LineProtocol.serialize(point).should eq("foo,test=bar a=1i #{ts}")
    end

    it "serializes without a timestamp (uses server rx time)" do
      point = Flux::Point.new "foo", a: 1_i64
      point.tag test: "bar"
      Flux::LineProtocol.serialize(point).should eq("foo,test=bar a=1i")
    end
  end
end

require "../spec_helper"

describe InfluxDB::LineProtocol do
  describe ".serialize" do
    time = Time.utc
    ts = time.to_unix

    it "serializes a simple point to line protocol" do
      point = InfluxDB::Point.new "foo", time, a: 1
      InfluxDB::LineProtocol.serialize(point).should eq("foo a=1 #{ts}")
    end

    it "serializes a multi-field point to line protocol" do
      point = InfluxDB::Point.new "foo", time, a: 1, b: true
      InfluxDB::LineProtocol.serialize(point).should eq("foo a=1,b=t #{ts}")
    end

    it "serializes when tags are present" do
      point = InfluxDB::Point.new "foo", time, a: 1
      point.tag test: "bar"
      InfluxDB::LineProtocol.serialize(point).should eq("foo,test=bar a=1 #{ts}")
    end
  end
end

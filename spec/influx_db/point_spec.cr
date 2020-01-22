require "../spec_helper"

describe InfluxDB::Point do
  describe ".new" do
    it "maps fields into a FieldSet" do
      point = InfluxDB::Point.new "foo", a: 1_u64, b: "test", c: 0.0, d: false
      point.fields.should eq({
        :a => 1_u64,
        :b => "test",
        :c => 0.0,
        :d => false,
      })
    end
  end

  describe ".new!" do
    it "maps fields into a FieldSet, discarding those with nil values" do
      point = InfluxDB::Point.new! "foo", a: 1_u64, b: "test", c: nil, d: nil
      point.fields.should eq({
        :a => 1_u64,
        :b => "test",
      })
    end
  end

  describe "#tag" do
    it "allows tagging of points" do
      point = InfluxDB::Point.new "foo", a: 1_u64
      point.tag test: "bar"
      point.tags.should eq({:test => "bar"})
    end
  end

  describe "to_s" do
    it "serializes to line procotol" do
      time = Time.utc
      ts = time.to_unix
      point = InfluxDB::Point.new "foo", time, a: 1_u64
      point.tag test: "bar"
      point.to_s.should eq("foo,test=bar a=1u #{ts}")
    end
  end
end

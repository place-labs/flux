require "../spec_helper"

describe InfluxDB::Point do
  describe ".new" do
    it "detects missing fields" do
      expect_raises(ArgumentError) do
        InfluxDB::Point.new "foo"
      end
    end

    it "maps fields into a FieldSet" do
      point = InfluxDB::Point.new "foo", a: 1, b: "test", c: 0.0, d: false
      point.fields.should eq({
        :a => 1,
        :b => "test",
        :c => 0.0,
        :d => false,
      })
    end
  end

  describe "#tag" do
    it "allows tagging of points" do
      point = InfluxDB::Point.new "foo", a: 1
      point.tag :test, "bar"
      point.tags.should eq({:test => "bar"})
    end
  end

  describe "to_s" do
    it "serializes to line procotol" do
      time = Time.utc
      ts = time.to_unix
      point = InfluxDB::Point.new "foo", time, a: 1
      point.tag :test, "bar"
      point.to_s.should eq("foo,test=bar a=1 #{ts}")
    end
  end
end

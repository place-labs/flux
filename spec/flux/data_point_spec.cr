require "../spec_helper"

describe Flux::DataPoint do
  describe ".new" do
    it "detects missing fields" do
      expect_raises(ArgumentError) do
        Flux::DataPoint.new "foo"
      end
    end

    it "maps fields into a FieldSet" do
      point = Flux::DataPoint.new "foo", a: 1, b: "test", c: 0.0, d: false
      point.fields.should eq({
        :a => 1,
        :b => "test",
        :c => 0.0,
        :d => false
      })
    end
  end

  describe "#tag" do
    it "allows tagging of points" do
      point = Flux::DataPoint.new "foo", a: 1
      point.tag :test, "bar"
      point.tags.should eq({:test => "bar"})
    end
  end

  describe "#to_s" do
    time = Time.now
    ts = time.to_unix

    it "serializes a simple point to line protocol" do
      point = Flux::DataPoint.new "foo", time, a: 1
      point.to_s.should eq("foo a=1 #{ts}")
    end

    it "serializes a multi-field point to line protocol" do
      point = Flux::DataPoint.new "foo", time, a: 1, b: true
      point.to_s.should eq("foo a=1,b=t #{ts}")
    end

    it "serializes when tags are present" do
      point = Flux::DataPoint.new "foo", time, a: 1
      point.tag :test, "bar"
      point.to_s.should eq("foo,test=bar a=1 #{ts}")
    end
  end
end

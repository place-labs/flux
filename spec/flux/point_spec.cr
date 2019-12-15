require "../spec_helper"

describe Flux::Point do
  describe ".new" do
    it "detects missing fields" do
      expect_raises(ArgumentError) do
        Flux::Point.new "foo"
      end
    end

    it "maps fields into a FieldSet" do
      point = Flux::Point.new "foo", a: 1, b: "test", c: 0.0, d: false
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
      point = Flux::Point.new "foo", a: 1
      point.tag :test, "bar"
      point.tags.should eq({:test => "bar"})
    end
  end

  describe "to_s" do
    it "serializes to line procotol" do
      time = Time.utc
      ts = time.to_unix
      point = Flux::Point.new "foo", time, a: 1
      point.tag :test, "bar"
      point.to_s.should eq("foo,test=bar a=1 #{ts}")
    end
  end
end

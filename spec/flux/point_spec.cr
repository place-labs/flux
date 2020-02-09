require "../spec_helper"

describe Flux::Point do
  describe ".new" do
    it "maps fields into a FieldSet" do
      point = Flux::Point.new "foo", a: 1_u64, b: "test", c: 0.0, d: false
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
      point = Flux::Point.new! "foo", a: 1_u64, b: "test", c: nil, d: nil
      point.fields.should eq({
        :a => 1_u64,
        :b => "test",
      })
    end
  end

  describe "#tag" do
    it "allows tagging of points" do
      point = Flux::Point.new "foo", a: 1_u64
      point.tag test: "bar"
      point.tags.should eq({:test => "bar"})
    end
  end

  describe "to_s" do
    it "serializes to line procotol" do
      time = Time.utc(2009, 2, 13, 23, 31, 30)
      point = Flux::Point.new "foo", time, a: 1_u64
      point.tag test: "bar"
      point.to_s.should eq("foo,test=bar a=1u 1234567890000000000")
    end
  end
end

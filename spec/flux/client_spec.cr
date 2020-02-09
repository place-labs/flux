require "../spec_helper"

describe Flux::Client do
  client = Flux::Client.new "http://example.com", org: "foo", token: "abc"

  points = [] of Flux::Point
  100.times do
    points << Flux::Point.new "name", a: Random.rand
  end

  describe "#write" do
    it "writes single points" do
      WebMock.stub(:post, "http://example.com/api/v2/write")
        .with(
          headers: {
            "Authorization" => "Token abc",
          },
          query: {
            "bucket"    => "test",
            "org"       => "foo",
          },
          body: points.first.to_s
        )
      client.write "test", points.first
    end

    it "writes batches of points" do
      WebMock.stub(:post, "http://example.com/api/v2/write")
        .with(
          headers: {
            "Authorization" => "Token abc",
          },
          query: {
            "bucket"    => "test",
            "org"       => "foo",
          },
          body: points.join '\n'
        )
      client.write "test", points
    end
  end
end

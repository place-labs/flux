require "../spec_helper"

describe Flux::Client do
  client = Flux::Client.new "example.com", org: "foo", token: "abc"

  points = [] of Flux::DataPoint
  100.times do
    points << Flux::DataPoint.new "name", a: Random.rand
  end

  describe "#write" do
    it "writes single points" do
      WebMock.stub(:post, "http://example.com/api/v2/write")
             .with(
               headers: {
                 "Authorization" => "Token abc"
               },
               query: {
                 "bucket" => "test",
                 "precision" => "s",
                 "org" => "foo"
               },
               body: points.join '\n'
             )
      client.write "test", points
    end
  end
end

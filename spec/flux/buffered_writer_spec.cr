require "../spec_helper"

describe Flux::BufferedWriter do
  client = Flux::Client.new "http://example.com", org: "foo", token: "abc"
  writer = Flux::BufferedWriter.new client, bucket: "test", batch_size: 5, flush_delay: 100.milliseconds

  points = [] of Flux::Point
  13.times do
    points << Flux::Point.new "name", a: Random.rand
  end

  describe ".write" do
    build_mock = ->(body_points : Array(Flux::Point)) do
      WebMock.stub(:post, "http://example.com/api/v2/write")
        .with(
          headers: {
            "Authorization" => "Token abc",
          },
          query: {
            "bucket" => "test",
            "org"    => "foo",
          },
          body: body_points.join '\n'
        )
    end

    it "writes single points" do
      build_mock.call points[0, 1]
      writer.enqueue points.first
      sleep 0.1
    end

    it "writes multiple points as a single request" do
      points.each_slice 5, &build_mock
      points.each &->writer.enqueue(Flux::Point)
      sleep 0.3
    end
  end
end

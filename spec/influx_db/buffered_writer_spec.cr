require "../spec_helper"

describe InfluxDB::BufferedWriter do
  client = InfluxDB::Client.new "http://example.com", org: "foo", token: "abc"
  writer = InfluxDB::BufferedWriter.new client, bucket: "test", batch_size: 5, flush_delay: 100.milliseconds

  points = [] of InfluxDB::Point
  13.times do |idx|
    points << InfluxDB::Point["name", a: Random.rand, idx: idx]
  end

  describe ".write" do
    build_mock = ->(body_points : Array(InfluxDB::Point)) do
      WebMock.stub(:post, "http://example.com/api/v2/write")
        .with(
          headers: {
            "Authorization" => "Token abc",
          },
          query: {
            "bucket"    => "test",
            "precision" => "s",
            "org"       => "foo",
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
      points.each &->writer.enqueue(InfluxDB::Point)
      sleep 0.3
    end
  end
end

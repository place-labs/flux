require "./spec_helper"

describe Flux do
  describe ".configure" do
    it "raises an exception when passed an invalid config" do
      expect_raises(Exception) do
        Flux.configure {}
      end
    end
  end

  describe ".write" do
    point = InfluxDB::Point["name", a: Random.rand]

    it "raises an exception when not configured" do
      expect_raises(Exception) do
        Flux.write point
      end
    end

    it "writes single points" do
      Flux.configure do |settings|
        settings.host = "http://example.com"
        settings.api_key = "abc"
        settings.org = "foo"
        settings.bucket = "test"
      end

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
          body: point.to_s
        )

      Flux.write point
    end
  end
end

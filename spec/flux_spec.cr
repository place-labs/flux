require "./spec_helper"

describe Flux do
  describe ".configure" do
    it "raises an exception when passed an invalid config" do
      expect_raises(Exception) do
        Flux.configure { }
      end
    end
  end

  describe ".write" do
    points = [] of Flux::Point
    7.times do
      points << Flux::Point.new "name", a: Random.rand
    end

    context "when not configured" do
      it "raises an exception" do
        expect_raises(Exception) do
          Flux.write points.first
        end
      end
    end

    context "following global config" do
      it "writes single points" do
        Flux.configure do |settings|
          settings.host = "http://example.com"
          settings.api_key = "abc"
          settings.org = "foo"
          settings.bucket = "test"
          settings.flush_delay = 50.milliseconds
        end

        WebMock.stub(:post, "http://example.com/api/v2/write")
          .with(
            headers: {
              "Authorization" => "Token abc",
            },
            query: {
              "bucket" => "test",
              "org"    => "foo",
            },
            body: points.first.to_s
          )
        Flux.write points.first
        sleep 0.1
      end

      it "writes multiple points as a single request" do
        WebMock.stub(:post, "http://example.com/api/v2/write")
          .with(
            headers: {
              "Authorization" => "Token abc",
            },
            query: {
              "bucket" => "test",
              "org"    => "foo",
            },
            body: points.join '\n'
          )
        points.each &->Flux.write(Flux::Point)
        sleep 0.1
      end
    end
  end
end

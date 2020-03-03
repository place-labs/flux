require "json"
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
            "bucket" => "test",
            "org"    => "foo",
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
            "bucket" => "test",
            "org"    => "foo",
          },
          body: points.join '\n'
        )
      client.write "test", points
    end
  end

  describe "#query" do
    io = IO::Memory.new <<-CSV
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,string,string,double
      #group,false,false,false,false,false,true,false,false
      #default,,,,,,,,
      ,result,table,_start,_stop,_time,region,host,_value
      ,my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,east,A,15.43
      ,my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,east,B,59.25
      ,my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,east,C,52.62
      ,my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,west,A,62.73
      ,my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,west,B,12.83
      ,my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,west,C,51.62
      CSV

    before_each { io.rewind }

    WebMock.stub(:post, "http://example.com/api/v2/query")
      .with(
        headers: {
          "Authorization" => "Token abc",
          "Accept"        => "application/csv",
          "Content-type"  => "application/json",
        },
        query: {
          "org" => "foo",
        },
        body: {
          query:   "test",
          dialect: Flux::AnnotatedCSV::DIALECT,
        }.to_json
      )
      .to_return(io)

    it "provides untyped results" do
      tables = client.query "test"
      tables.first.first["region"].should eq("east")
    end

    it "provides the ablity to read into a known schema" do
      tables = client.query "test" do |row|
        {
          time:   Time::Format::RFC_3339.parse(row["_time"]),
          region: row["region"],
          host:   row["host"],
          value:  row["_value"].to_f,
        }
      end
      tables.first.first[:host].should eq("A")
    end
  end
end

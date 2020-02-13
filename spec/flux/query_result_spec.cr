require "../spec_helper"

describe Flux::QueryResult do
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

  describe ".parse" do
    tables = Flux::QueryResult.parse io

    it "passes an io into a set of table" do
      tables.size.should eq(2)
    end

    it "provides group keys" do
      tables.first.group_key.should eq(["region"])
    end

    it "maps values into entries within each table" do
      tables.first.first[7].should eq("A")
    end

    it "allows specifing a custom row parser" do
      result = Flux::QueryResult.parse io, &.to_h
      result.first.first["host"].should eq("A")
    end

    it "allows specifing a custom row parser2" do
      result = Flux::QueryResult.parse io do |row|
        {
          time: Time::Format::RFC_3339.parse(row["_time"]),
          region: row["region"],
          host: row["host"],
          value: row["_value"].to_f
        }
      end
      result.first.first[:host].should eq("A")
    end
  end
end

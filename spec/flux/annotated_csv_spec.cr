require "../spec_helper"

describe Flux::AnnotatedCSV do
  io = IO::Memory.new <<-CSV
    #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,string,string,double
    #group,false,false,false,false,false,false,false,false
    #default,,,,,,,,
    ,result,table,_start,_stop,_time,region,host,_value
    ,my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,east,A,15.43
    ,my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,east,B,59.25
    ,my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,east,C,52.62
    ,my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,west,A,62.73
    ,my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,west,B,12.83
    ,my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,west,C,51.62
    CSV
  csv = Flux::AnnotatedCSV.new io, headers: true

  it "provides extractions from the base CSV class", focus: true do
    csv.headers.should eq(["", "result", "table", "_start", "_stop", "_time",
                           "region", "host", "_value"])
  end

  describe "#annotations" do
    it "provides an array with a hash of annotations for each column" do
      csv.annotations.should be_a(Array(Hash(String, String)))
      csv.annotations[1].should eq({
        "datatype" => "string",
        "group"    => "false",
        "default"  => "",
      })
    end

    it "supports lookups based on header names" do
      csv.annotations("_value").should eq({
        "datatype" => "double",
        "group"    => "false",
        "default"  => "",
      })
    end
  end
end

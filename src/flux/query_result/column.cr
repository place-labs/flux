require "./data_type"

struct Flux::QueryResult::Column
  getter name : String

  getter type : DataType

  getter group : Bool

  getter default : String

  def initialize(@name, @type, @group, @default)
  end
end

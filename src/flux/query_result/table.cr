require "./column"

struct Flux::QueryResult::Table(T)
  include Indexable(T)

  getter columns : Array(Column)

  private getter records = [] of T

  def initialize(@columns)
  end

  delegate each, :<<, unsafe_fetch, size, to: records

  def group_key
    columns.select(&.group).map(&.name)
  end
end

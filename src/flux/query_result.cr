require "./annotated_csv"
require "./query_result/*"

# Parsers and data structures for working with returned query results.
module Flux::QueryResult
  extend self

  # FIXME: support query results containing mutliple schemas
  def parse(io : IO) : Enumerable(Table(Array(String)))
    tables = [] of Table(Array(String))

    AnnotatedCSV.new(io, headers: true).each do |csv|
      idx = csv["table"].to_i
      table = tables[idx]?

      unless table
        columns = csv.headers.map do |name|
          meta = csv.annotations name
          Column.new(
            name: name,
            type: DataType.parse(meta["datatype"]),
            group: meta["group"] == "true",
            default: meta["default"]
          )
        end
        table = Table(Array(String)).new columns
        tables << table
      end

      table << csv.row.to_a
    end

    tables
  end
end

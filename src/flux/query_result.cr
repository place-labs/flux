require "./annotated_csv"
require "./query_result/*"

# Parsers and data structures for working with returned query results.
#
# FIXME: support query results containing mutliple schemas
module Flux::QueryResult
  extend self

  # Parses a response into a set of tables with each row as an Array of Strings.
  def parse(string_or_io : String | IO) : Enumerable(Table(Array(String)))
    parse string_or_io, &.to_a
  end

  # Parses a response into a set of tables, using the passed block to map to the
  # record types.
  def parse(string_or_io : String | IO, &block : CSV::Row -> T) : Enumerable(Table(T)) forall T
    parse string_or_io { |row, _| block.call row }
  end

  # :ditto:
  def parse(string_or_io : String | IO, &block : CSV::Row, Array(Column) -> T) : Enumerable(Table(T)) forall T
    tables = [] of Table(T)

    AnnotatedCSV.new(string_or_io, headers: true).each do |csv|
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
        table = Table(T).new columns
        tables << table
      end

      table << block.call(csv.row, table.columns)
    end

    tables
  end
end

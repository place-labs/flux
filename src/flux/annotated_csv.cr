require "csv"

# Extensions to the base CSV class to support a set of annotation rows
# containing additional column metadat.
#
# Annotations are rows that have been prefixed with a `#`. These must appear
# prior to any headers or data.
class Flux::AnnotatedCSV < CSV
  ANNOTATION_CHAR = '#'

  # Dialect options for query responses.
  # See: https://www.w3.org/TR/2015/REC-tabular-metadata-20151217/#dialect-descriptions
  DIALECT = {
    header:         true,
    annotations:    ["group", "datatype", "default"],
    commentPrefix:  ANNOTATION_CHAR.to_s,
    dateTimeFormat: "RFC3339",
  }

  @annotations : Array(Hash(String, String))?

  def initialize(string_or_io : String | IO, headers = false, @strip = false, separator : Char = DEFAULT_SEPARATOR, quote_char : Char = DEFAULT_QUOTE_CHAR)
    @parser = Parser.new(string_or_io, separator, quote_char)
    cols = @parser.next_row || ([] of String)
    count = 0
    while cols.first?.try &.starts_with?(ANNOTATION_CHAR)
      count += 1
      type = cols[0].lchop ANNOTATION_CHAR
      if annotations = @annotations
        annotations.zip(cols) { |col, value| col[type] = value }
      else
        @annotations = cols.map { |value| {type => value} }
      end
      cols = @parser.next_row || ([] of String)
    end

    if headers
      headers = @headers = cols.map &.strip
      indices = @indices = {} of String => Int32
      headers.each_with_index do |header, index|
        indices[header] ||= index
      end
    else
      # we are one row ahead of where we should be so need to rewind
      @parser.rewind
      count.times { @parser.next_row }
    end

    @traversed = false
  end

  # Provides an array containing the annotations for each column.
  def annotations
    @annotations || raise Error.new("No annotations in parsed source")
  end

  # Provides annotations for the passed column.
  def annotations(header : String)
    index = indices[header]
    annotations[index]
  end
end

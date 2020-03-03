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

    while @parser.peek == ANNOTATION_CHAR && (cols = @parser.next_row)
      type = cols[0].lchop ANNOTATION_CHAR
      if annotations = @annotations
        annotations.zip(cols) { |col, value| col[type] = value }
      else
        @annotations = cols.map { |value| {type => value} }
      end
    end

    if headers
      headers = @parser.next_row || ([] of String)
      headers = @headers = headers.map &.strip
      indices = @indices = {} of String => Int32
      headers.each_with_index do |header, index|
        indices[header] ||= index
      end
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

class CSV::Parser
  protected def peek
    @lexer.peek
  end
end

abstract class CSV::Lexer
  protected def peek
    current_char
  end
end

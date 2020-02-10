enum Flux::QueryResult::DataType
  Annotation
  Boolean
  UnsignedLong
  Long
  Double
  String
  Base64Binary
  DateTime
  Duration

  def self.parse(string : ::String) : self
    if string.starts_with? '#'
      Annotation
    else
      # Types can have an optional encodeding appended. This appears to be
      # static though? e.g `dateTime:RFC3339`.
      super string.split(':')[0]
    end
  end
end

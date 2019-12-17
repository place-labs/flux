require "./line_protocol"

# Model for InfluxDB data points.
struct InfluxDB::Point
  alias TagSet = Hash(Symbol, String | Symbol)

  alias FieldSet = Hash(Symbol, Float32 | Float64 | Int32 | Int64 | UInt32 |
                        UInt64 | Bool | String)

  getter measurement : String

  getter(tags) { TagSet.new }

  getter fields : FieldSet

  getter timestamp : Time?

  def self.[](measurement, timestamp = nil, **fields)
    new measurement, timestamp, **fields
  end

  # Creates a new data point that can be serialized for entry to InfluxDB.
  def initialize(@measurement, @timestamp = nil, @tags = nil, **fields : **T) forall T
    raise ArgumentError.new "points must include at least one field" if fields.empty?

    # FIXME refactor / neaten up when time allows
    @fields = FieldSet.new
    {% for k in T %}
      @fields[{{k.symbolize}}] = fields[{{k.symbolize}}].not_nil! \
        unless fields[{{k.symbolize}}].nil?
    {% end %}
  end

  # Append or change tags associated with the point.
  def tag(**t : **T) forall T
    {% for k in T %}
      tags[{{k.symbolize}}] = t[{{k.symbolize}}]
    {% end %}
  end

  # Checks if any tags are defined for the point.
  def tagged?
    !@tags.nil?
  end

  def to_s(io)
    LineProtocol.serialize self, io
  end
end

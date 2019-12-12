require "./line_protocol"

# Model for InfluxDB data points.
struct Flux::DataPoint
  alias TagSet = Hash(Symbol, String | Symbol)

  alias FieldSet = Hash(Symbol, Float32 | Float64 | Int32 | Int64 | Bool | String)

  getter measurement : String

  getter(tags) { TagSet.new }

  getter fields : FieldSet

  getter timestamp : Time

  # Creates a new data point that can be serialized for entry to InfluxDB.
  def initialize(@measurement, @timestamp = Time.now, @tags = nil, **fields : **T) forall T
    raise ArgumentError.new "points must include at least one field" if fields.empty?

    @fields = FieldSet.new
    {% for k in T %}
      @fields[{{k.symbolize}}] = fields[{{k.symbolize}}]
    {% end %}
  end

  # Append or change a tag on the point.
  def tag(key, value)
    tags[key] = value
  end

  # Checks if any tags are defined for the point.
  def tagged?
    !@tags.nil?
  end

  def to_s(io)
    LineProtocol.serialize self, io
  end
end

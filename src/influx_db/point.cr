require "./line_protocol"

# Model for InfluxDB data points.
#
# TODO: make this generic over a NamedTuple of the associated fields. Currently
# this causes issues elsewhere as you can not have an `Array`, `Channel` etc of
# a generic type.
struct InfluxDB::Point
  alias TagSet = Hash(Symbol, String)

  alias FieldType = Float64 | Int64 | UInt64 | String | Bool

  alias FieldSet = Hash(Symbol, FieldType)

  getter measurement : String

  getter(tags) { TagSet.new }

  getter fields = FieldSet.new

  getter timestamp : Time?

  def self.[](measurement, timestamp = nil, **fields)
    new measurement, timestamp, **fields
  end

  # Creates a new data point that can be serialized for entry to InfluxDB.
  def initialize(@measurement, @timestamp = nil, @tags = nil, **fields : **T) forall T
    {% raise "points must have at least one field" if T.keys.empty? %}

    {% for key, type in T %}
      {% unless FieldType.union_types.includes? type %}
        {% raise "invalid type for #{key} (#{type}) - fields must be one of #{FieldType.union_types.join(", ").id}" %}
      {% end %}

      self.fields[{{key.symbolize}}] = fields[{{key.symbolize}}]
    {% end %}
  end

  # Append or change tags associated with the point.
  def tag(**tags : **T) forall T
    {% for key in T %}
      self.tags[{{key.symbolize}}] = tags[{{key.symbolize}}]
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

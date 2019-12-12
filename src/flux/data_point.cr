# Model and serialization tools for InfluxDB data points.
struct Flux::DataPoint
  alias TagSet = Hash(Symbol, String | Symbol)

  alias FieldSet = Hash(Symbol, Float32 | Float64 | Int32 | Int64 | Bool | String)

  getter measurement : String

  getter(tags) { TagSet.new }

  getter fields : FieldSet

  getter timestamp : Time

  # Creates a new data point that can be serialized for entry to InfluxDB.
  def initialize(@measurement, @timestamp = Time.now, @tags = nil, **fields : **T) forall T
    raise ArgumentError.new "data points must include at least one field" \
      if fields.empty?

    @fields = FieldSet.new
    {% for k in T %}
      @fields[{{k.symbolize}}] = fields[{{k.symbolize}}]
    {% end %}
  end

  # Append or change a tag on the point.
  def tag(key, value)
    tags[key] = value
  end

  # Serializes the point to InfluxDB line protocol.
  # See https://v2.docs.influxdata.com/v2.0/reference/syntax/line-protocol/
  def to_s(io : IO)
    io << @measurement

    @tags.try(
      &.each do |k, v|
        io << ','
        io << k
        io << '='
        io << v
      end
    )

    io << ' '

    fields.join(',', io) do |(k, v), field|
      field << k
      field << '='
      case v
      when String
        field << '"'
        field << v
        field << '"'
      when true
        field << 't'
      when false
        field << 'f'
      else
        field << v
      end
    end

    io << ' '

    io << timestamp.to_unix
  end
end

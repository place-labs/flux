# Model and serialization tools for InfluxDB data points.
struct Flux::DataPoint
  alias TagSet = Hash(Symbol, String | Symbol)

  alias FieldSet = Hash(Symbol, Float32 | Float64 | Int32 | Int64 | Bool | String)

  getter measurement : String

  getter(tags) { TagSet.new }

  getter fields : FieldSet

  getter timestamp : Time

  def initialize(@measurement, @timestamp = Time.now, @tags = nil, **fields : **T) forall T
    raise ArgumentError.new "data points must include at least one field" \
      if fields.empty?

    @fields = FieldSet.new
    {% for k in T %}
      @fields[{{k.symbolize}}] = fields[{{k.symbolize}}]
    {% end %}
  end

  def tag(key, value)
    tags[key] = value
  end

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

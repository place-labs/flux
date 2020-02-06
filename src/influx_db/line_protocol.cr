require "./point"

# Tools for line protocol marshalling.
# See https://v2.docs.influxdata.com/v2.0/reference/syntax/line-protocol/
# TODO: escape special chars
module InfluxDB::LineProtocol
  # Appends *point* onto *io* in line protocol format.
  def self.serialize(point : Point, io : IO) : Nil
    io << point.measurement

    if point.tagged?
      point.tags.each do |k, v|
        io << ','
        io << k
        io << '='
        io << v
      end
    end

    io << ' '

    point.fields.join(',', io) do |(k, v), field|
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
      when Int::Signed
        field << v
        field << 'i'
      when Int::Unsigned
        field << v
        field << 'u'
      when Float
        field << v
      end
    end

    point.timestamp.try &.to_s " %s%N", io

    io
  end

  # Serializes *point* to a line protocol row.
  def self.serialize(point : Point) : String
    String.build do |io|
      serialize point, io
    end
  end
end

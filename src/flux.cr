require "./influx_db/*"
# require "./flux/*"

module Flux
  VERSION = `shards version`

  class Options
    property host : String? = nil
    property api_key : String? = nil
    property org : String? = nil
    property bucket : String? = nil
    property batch_size : Int32 = 5000
    property flush_delay : Time::Span = 1.seconds
    property logger : Logger? = nil
  end

  # Global client instance used by module level convinience wrappers.
  @@client : InfluxDB::Client?

  # Global writer instance used by module level convinience wrappers.
  @@writer : InfluxDB::BufferedWriter?

  # Sets the root config used by `Flux.write` and `Flux.query` and create a
  # global client based on this.
  def self.configure : Nil
    @@client = nil
    @@writer = nil

    config = Options.new
    yield config

    @@client = InfluxDB::Client.new(
      host: config.host.not_nil!,
      token: config.api_key.not_nil!,
      org: config.org.not_nil!,
      logger: config.logger
    )

    @@writer = InfluxDB::BufferedWriter.new(
      client: @@client.not_nil!,
      bucket: config.bucket.not_nil!,
      batch_size: config.batch_size,
      flush_delay: config.flush_delay
    )
  rescue NilAssertionError
      raise "Incomplete configuration - host, token, org and bucket must be specified"
  end

  # Writes a point the default configured bucket.
  def self.write(point)
    writer = @@writer.not_nil!
    writer.enqueue point
  rescue NilAssertionError
    raise "Global config invalid or not set - use Flux.configure"
  end

  # Executes a query on a the globally configured instance.
  def self.query(expression)
    client = @@client.no_nil!
    client.query expression
  rescue NilAssertionError
    raise "Global config invalid or not set - use Flux.configure"
  end
end

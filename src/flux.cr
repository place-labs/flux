require "./influx_db/*"
# require "./flux/*"

module Flux
  VERSION = `shards version`

  class Options
    property host : String? = nil
    property api_key : String? = nil
    property org : String? = nil
    property bucket : String? = nil
  end

  # Global client isntance used by module level convinience wrappers.
  @@client : InfluxDB::Client?

  # Defautl bucket for writes by the global client.
  @@bucket : String?

  # Sets the root config used by `Flux.write` and `Flux.query` and create a
  # global client based on this.
  def self.configure : Nil
    config = Options.new
    yield config
    begin
      @@bucket = config.bucket.not_nil!
      @@client = InfluxDB::Client.new(
        host: config.host.not_nil!,
        token: config.api_key.not_nil!,
        org: config.org.not_nil!
      )
    rescue NilAssertionError
      @@client = nil
      raise "Incomplete configuration"
    end
  end

  # Writes a point the default configured bucket.
  def self.write(point, bucket = @@bucket.not_nil!)
    client.write bucket, point
  end

  # Executes a query on a the globally configured instance.
  def self.query(expression)
    client.query expression
  end

  # Gets a shared global client.
  private def self.client
    @@client.not_nil!
  rescue NilAssertionError
    raise "Global config invalid or not set - use Flux.configure"
  end
end

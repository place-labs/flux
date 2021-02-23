require "./flux/client"
require "./flux/buffered_writer"

module Flux
  VERSION = `shards version`

  class Options
    property uri : String? = nil
    property api_key : String? = nil
    property org : String? = nil
    property bucket : String? = nil
    property batch_size : Int32 = 5000
    property flush_delay : Time::Span = 1.seconds
  end

  # Global client instance used by module level convinience wrappers.
  @@client : Flux::Client?

  # Global writer instance used by module level convinience wrappers.
  @@writer : Flux::BufferedWriter?

  # Sets the root config used by `Flux.write` and `Flux.query` and create a
  # global client based on this.
  def self.configure : Nil
    @@client = nil
    @@writer = nil

    yield (config = Options.new)

    @@client = Flux::Client.new(
      uri: config.uri.not_nil!,
      token: config.api_key.not_nil!,
      org: config.org.not_nil!,
    )

    @@writer = Flux::BufferedWriter.new(
      client: @@client.not_nil!,
      bucket: config.bucket.not_nil!,
      batch_size: config.batch_size,
      flush_delay: config.flush_delay
    )
  rescue NilAssertionError
    raise "Incomplete configuration - uri, token, org and bucket must be specified"
  end

  private def self.client
    @@client || raise "Global config invalid or not set - use Flux.configure before accessing client"
  end

  private def self.writer
    @@writer || raise "Global config invalid or not set - use Flux.configure before accessing writer"
  end

  # Writes a point the default configured bucket.
  def self.write(point)
    writer.enqueue point
  end

  # Executes a query on a the globally configured instance.
  def self.query(expression)
    client.query expression
  end

  # :ditto:
  def self.query(expression, &block : QueryResult::Row, Array(QueryResult::Column) -> T) forall T
    client.query expression, &block
  end
end

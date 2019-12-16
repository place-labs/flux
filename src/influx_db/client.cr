require "http/client"
require "uri"
require "./point"

class InfluxDB::Client
  private getter connection : HTTP::Client

  delegate :connect_timeout=, :read_timeout=, to: connection

  # Creates a new InfluxDB client for the instance running at the specified
  # *url*.
  #
  # *token* must be a valid API token on the instance that provides sufficient
  # privaleges for the buckets being interact with. Similarly *org* must match
  # the appropriate *org* name these buckets sit under.
  def initialize(host, token : String, org : String)
    uri = URI.parse host
    @connection = HTTP::Client.new uri

    connection.before_request do |req|
      req.headers["Authorization"] = "Token #{token}"
      req.path = "/api/v2#{req.path}"
      req.query_params["org"] = org
    end
  end

  # Writes a single *point* to the passed *bucket*.
  def write(bucket : String, point : Point)
    # OPTIMIZE: cache single point requests and right after reaching threshold
    # or max hold time.
    write_internal bucket do |io|
      io << point
    end
  end

  # Writes a set of *points* to the passed *bucket*.
  def write(bucket : String, points : Enumerable(Point)) : Nil
    write_internal bucket do |io|
      points.join '\n', io
    end
  end

  # Write a set of data points to *bucket* on the connected instance.
  #
  # Yields an IO. Points to be written should be appended to this.
  private def write_internal(bucket : String, &block : IO -> _)
    buf = IO::Memory.new
    yield buf
    buf.rewind
    write_internal bucket, buf
  end

  # Write a set of data points to *bucket* on the connected instance.
  # TODO: check influx support for chunked transfer encoding
  private def write_internal(bucket : String, data : IO)
    params = HTTP::Params.build do |param|
      param.add "bucket", bucket
      param.add "precision", "s"
    end

    request = HTTP::Request.new "POST", "/write?#{params}", body: data
    request.content_length = data.size
    response = connection.exec request

    # TODO parse responses into domain specific errors
    unless response.success?
      raise "Error writing data points (HTTP #{response.status_code})"
    end
  end

  # Runs a query on the connected InfluxDB instance.
  #
  # *expression* must be a valid Flux expression.
  def query(expression : String)
    headers = HTTP::Headers.new
    headers.add "Accept", "application/csv"
    headers.add "Content-type", "application/vnd.flux"

    response = connection.post "/query", headers, body

    # TODO parse responses into domain specific errors
    unless response.success?
      raise "Error writing data points (HTTP #{response.status_code})"
    end

    response.body_io
  end
end

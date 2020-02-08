require "http/client"
require "logger"
require "uri"
require "./point"
require "./errors"

class InfluxDB::Client
  getter log : Logger

  private getter connection : HTTP::Client

  delegate :connect_timeout=, :read_timeout=, to: connection

  # Creates a new InfluxDB client for the instance running at the specified
  # *url*.
  #
  # *token* must be a valid API token on the instance that provides sufficient
  # privaleges for the buckets being interact with. Similarly *org* must match
  # the appropriate *org* name these buckets sit under.
  def initialize(host, token : String, org : String, logger = nil)
    @log = logger || Logger.new STDOUT, level: Logger::WARN

    uri = URI.parse host
    @connection = HTTP::Client.new uri

    connection.before_request do |req|
      req.headers["Authorization"] = "Token #{token}"
      req.path = "/api/v2#{req.path}"
      req.query_params["org"] = org
    end
  end

  # Perform a synchronous write of a single *point* to the passed *bucket*.
  #
  # In most cases this _should not_ be used due the associated request overhead.
  # When writing points intermittently a `Writer` can be used to provide
  # buffering and batching.
  def write(bucket : String, point : Point)
    write_internal bucket do |io|
      io << point
    end
  end

  # Perform a synchronous write of a set of *points* to the passed *bucket*.
  def write(bucket : String, points : Enumerable(Point))
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
    end

    request = HTTP::Request.new "POST", "/write?#{params}", body: data
    request.content_length = data.size

    response = connection.exec request

    # FIXME: currently this is triggering a compiler bug. Re-enable status code
    # checked when resolved.
    # See: https://github.com/crystal-lang/crystal/issues/7113
    # Result.from(response).is(HTTP::Status::NO_CONTENT).value

    Result.from(response).value
  end

  # Runs a query on the connected InfluxDB instance.
  #
  # *expression* must be a valid Flux expression.
  def query(expression : String)
    headers = HTTP::Headers.new
    headers.add "Accept", "application/csv"
    headers.add "Content-type", "application/vnd.flux"

    response = connection.post "/query", headers, body

    Result.from(response).map(&.body_io).value
  end
end

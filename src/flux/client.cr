require "http/client"
require "log"
require "uri"
require "db/pool"

require "./errors"
require "./point"
require "./query_result"

class Flux::Client
  Log = ::Log.for(self)

  # Creates a new InfluxDB client for the instance running at the specified
  # *url*.
  #
  # *token* must be a valid API token on the instance that provides sufficient
  # privaleges for the buckets being interact with. Similarly *org* must match
  # the appropriate *org* name these buckets sit under.
  def initialize(host, @token : String, @org : String)
    @uri = URI.parse host
    @connection_pool = DB::Pool(HTTP::Client).new(max_idle_pool_size: 10) do
      connection = HTTP::Client.new(@uri)
      connection.before_request do |req|
        req.headers["Authorization"] = "Token #{@token}"
        req.path = "/api/v2#{req.path}"
        req.query_params["org"] = @org
      end
      connection
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
      points.join io, '\n'
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

    response = @connection_pool.checkout do |connection|
      connection.exec request
    end
    check_response! response

    nil
  end

  # Runs a query on the connected InfluxDB instance.
  #
  # *expression* must be a valid Flux expression. All returned records will by a
  # Hash of String => String. To parse into stricter types, use variant of this
  # method accepting a block.
  def query(expression : String)
    query_internal expression do |io|
      QueryResult.parse(io) { |row, _| row.to_h }
    end
  end

  # Runs a query on the connected InfluxDB instance.
  #
  # *expression* must be a valid Flux expression.
  def query(expression : String, &block : QueryResult::Row, Array(QueryResult::Column) -> T) forall T
    query_internal expression do |io|
      QueryResult.parse io, &block
    end
  end

  # Runs a query on the connected InfluxDB instance, returning the result.
  private def query_internal(expression : String, &block : IO -> T) : T forall T
    headers = HTTP::Headers.new
    headers.add "Accept", "application/csv"
    headers.add "Content-Type", "application/json"

    body = {
      query:   expression,
      dialect: AnnotatedCSV::DIALECT,
    }.to_json

    @connection_pool.checkout do |connection|
      connection.post "/query", headers, body do |response|
        check_response! response
        yield response.body_io
      end
    end
  end

  # Checks a HTTP response and raises an error if the status was not successful.
  private def check_response!(response : HTTP::Client::Response) : Nil
    Error.from(response).try { |e| raise e }
  end
end

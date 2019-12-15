require "http/client"
require "uri"
require "./point"

class InfluxDB::Client
  private getter connection : HTTP::Client

  delegate :connect_timeout=, :read_timeout=, to: connection

  def initialize(url, token : String, org : String)
    @connection = HTTP::Client.new url

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
    write bucket, {point}
  end

  # Writes a set of *points* to the passed *bucket*.
  def write(bucket : String, points : Enumerable(Point)) : Nil
    params = HTTP::Params.build do |param|
      param.add "bucket", bucket
      param.add "precision", "s"
    end

    response = connection.post "/write?#{params}", body: points.join '\n'

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

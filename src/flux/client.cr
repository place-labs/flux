require "http/client"
require "uri"
require "./point"

class Flux::Client
  private getter connection : HTTP::Client

  delegate :connect_timeout=, :read_timeout=, to: connection

  def initialize(host, org : String, token : String)
    @connection = HTTP::Client.new host

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

    unless response.success?
      raise "Error writing data points (HTTP #{response.status})"
    end
  end

  def query
    raise NotImplementedError.new
  end
end

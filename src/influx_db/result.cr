require "http/client/response"
require "burrito/either"
require "./errors"

module InfluxDB::Result
  alias Type = Either(InfluxDB::Error, HTTP::Client::Response)

  def self.from(response : HTTP::Client::Response)
    error = Error.from response
    if error
      Type.left error
    else
      Type.right response
    end
 end
end

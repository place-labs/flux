require "http/client/response"
require "json"

module Flux
  # Base class for all error types originating from interaction with InfluxDB.
  abstract class Error < Exception
    # Contructs a concrete error object from a client response.
    def self.from(response : HTTP::Client::Response) : Error?
      case response.status_code
      when 429
        retry_after = (response.headers["Retry-After"]? || 30).to_i
        TooManyRequests.new message_from(response), retry_after
      when 400..499
        ClientError.new message_from(response)
      when 500..599
        ServerError.new message_from(response)
      end
    end

    def self.message_from(response : HTTP::Client::Response) : String
      begin
        JSON.parse(response.body || response.body_io)["message"].as_s
      rescue
        response.status_message || "HTTP #{response.status_code})"
      end
    end
  end

  class ClientError < Error; end

  class TooManyRequests < ClientError
    getter retry_after : Int32

    def initialize(@message, @retry_after = 30)
      super "Rate limited (retry after #{retry_after})"
    end
  end

  class ServerError < Error; end

  class UnexpectedResponse < Error
    def initialize(status : HTTP::Status, expected : HTTP::Status)
      super "Unexpected response (received #{status}, expected #{expected})"
    end
  end
end

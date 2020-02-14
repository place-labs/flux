require "http/client/response"

module Flux
  # Base class for all error types originating from interaction with InfluxDB.
  abstract class Error < Exception
    # Contructs a concrete error object from a client response.
    def self.from(response : HTTP::Client::Response) : Error?
      message = response.status_message || "HTTP #{response.status_code})"
      case response.status_code
      when 200..299
        nil
      when 429
        retry_after = (response.headers["Retry-After"]? || 30).to_i
        TooManyRequests.new message, retry_after
      when 400..499
        ClientError.new message
      when 500..599
        ServerError.new message
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
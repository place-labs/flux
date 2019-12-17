module InfluxDB
  def self.check_response(response)
    case response.status_code
    when 200..299
      puts "Done"
      # All good
      nil
    when 429
      retry_after = (response.headers["Retry-After"]? || 30).to_i
      raise TooManyRequests.new response.status_message, retry_after
    when 400..499
      raise ClientError.new response.status_message
    when 500..599
      raise ServerError.new response.status_message
    end
  end

  class Error < Exception; end

  class ClientError < Error; end

  class TooManyRequests < ClientError
    getter retry_after : Int32
    def initialize(msg = nil, @retry_after = 30)
      super msg
    end
  end

  class ServerError < Error; end
end

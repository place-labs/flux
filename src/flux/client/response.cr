require "http/client/response"
require "burrito/either"
require "../errors"

struct Flux::Client::Response
  alias Type = Either(Flux::Error, HTTP::Client::Response)

  def self.from(response : HTTP::Client::Response)
    error = Error.from response
    if error
      failure error
    else
      success response
    end
  end

  def self.failure(error)
    new Type.left error
  end

  def self.success(response)
    new Type.right response
  end

  private def initialize(@result : Type); end

  forward_missing_to @result

  def is(expected : HTTP::Status)
    @result = @result.bind do |response|
      if response.status == expected
        @result
      else
        Type.left UnexpectedResponse.new(response.status, expected)
      end
    end

    self
  end
end

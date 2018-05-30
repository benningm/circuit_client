require 'json'

module CircuitClient
  class ClientError < Faraday::Error::ClientError
    def initialize(ex, response = nil)
      content_type = ex[:headers]['Content-Type']
      if !content_type.nil? && content_type.match(/application\/json/)
        begin
          error = JSON.parse(ex[:body])
          super("server response: #{error['errorDescription'] || error} (status: #{ex[:status]})")
        rescue JSON::ParserError
          super("server response with status #{ex[:status]} and malformed JSON")
        end
      else
        super(ex, response)
      end
    end
  end
end

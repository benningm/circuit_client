require 'circuit_client/errors'

module CircuitClient
  class ErrorMiddleware < Faraday::Response::RaiseError
    CLIENT_ERROR_STATUSES = (400...500).freeze

    def on_complete(env)
      case env[:status]
      when CLIENT_ERROR_STATUSES
        raise CircuitClient::ClientError, response_values(env)
      end

      super
    end
  end
end

require 'faraday'
require 'uri'
require 'json'

require 'circuit_client/error_middleware'

module CircuitClient
  # client for accessing circuit API
  class Client
    # Set the hostname of the circuit system
    # Default: eu.yourcircuit.com
    attr_accessor :host

    # The base path of the API
    # Default: /rest/v2
    attr_accessor :base_path

    # The protocol to use 'http' or 'https'
    # Default: 'https'
    attr_accessor :protocol

    # Timeout for http requests
    # Default: 60
    attr_accessor :timeout

    # The client_id for authentication
    attr_accessor :client_id

    # The client_secret for authentication
    attr_accessor :client_secret

    # The authentication method to use (currently only :client_credentials supported)
    attr_accessor :auth_method

    # Comma-delimited set of permissions that the application requests
    # ALL, READ_USER_PROFILE, WRITE_USER_PROFILE, READ_CONVERSATIONS, WRITE_CONVERSATIONS, READ_USER, CALLS
    # Default: ALL
    attr_accessor :auth_scope

    # Enable tracing (outputs http requests to STDOUT)
    # Default: false (disabled)
    attr_accessor :trace

    # Initialize a new client
    # 
    # Examples
    #
    #   CircuitClient::Client.new do |c|
    #     c.client_id = '4de34a3...'
    #     c.client_secret = '234df2...'
    #   end
    #
    # Returns a new CircuitClient::Client
    def initialize
      @host = 'eu.yourcircuit.com'
      @base_path = '/rest/v2'
      @protocol = 'https'
      @auth_method = :client_credentials
      @auth_scope = 'ALL'
      @timeout = 60
      @trace = false
      yield self
    end

    # The faraday http connection object
    def connection
      @connection ||= Faraday.new(url: base_uri.to_s) do |c|
        c.response :logger if @trace
        c.use CircuitClient::ErrorMiddleware
        c.adapter Faraday.default_adapter
      end
    end

    # The token used for authentication
    def access_token
      return @access_token unless @access_token.nil?
      case @auth_method
      when :client_credentials
        auth_client_credentials
      else
        raise "Unknown auth_method: #{@auth_method}"
      end
    end

    # Authenticate using client_credentials method
    def auth_client_credentials
      raise 'client_id parameter required' if @client_id.nil?
      raise 'client_secret parameter required' if @client_secret.nil?

      response = connection.post(build_uri('/oauth/token')) do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(
          client_id: @client_id,
          client_secret: @client_secret,
          grant_type: 'client_credentials',
          scope: @auth_scope
        )
      end

      data = JSON.parse(response.body)
      data['access_token']
    end

    # Return URI with path elements
    def base_uri
      URI("#{@protocol}://#{@host}")
    end

    # Returns an URI with the base_uri and the supplied path
    def build_uri(path)
      uri = base_uri
      uri.path = path
      uri.to_s
    end

    # Returns an URI and with a path relative to the base_path of the API
    def build_api_uri(path)
      build_uri("#{@base_path}#{path}")
    end

    # Create a new message in a existing conversation
    #
    # Examples
    #
    #   client.create_message(
    #     '<convId>',
    #     'my message text...',
    #     subject: 'Todays meeting'
    #   )
    #
    # To send to an existing message item use :item_id parameter:
    #
    #   client.create_message(
    #     '<convId>',
    #     'my message text...',
    #     item_id: 'itemId'
    #   )
    #
    def create_message(conv, text, **options)
      item_id = options[:item_id]
      path = "/conversations/#{conv}/messages"
      path += "/#{item_id}" unless item_id.nil?
      options.delete(:item_id)
      call(
        :post,
        path,
        content: text,
        **options
      )
    end

    # List all conversation of the user
    def list_conversations
      call(:get, '/conversations')
    end

    # Create a new group conversation
    def create_group_conversation(participants, topic)
      call(
        :post,
        '/conversations/group',
        participants: participants,
        topic: topic
      )
    end

    # Create a new 1:1 conversation
    def create_direct_conversation(participant)
      call(
        :post,
        '/conversations/direct',
        participant: participant
      )
    end

    # Remove participants from a conversation
    def delete_group_conversation_participants(conv, participants)
      call(
        :delete,
        "/conversations/group/#{conv}/participants",
        participants: participants
      )
    end

    # Remove the current_user from a conversation
    def leave_group_conversation(conv)
      delete_group_conversation_participants(conv, [current_user['userId']])
    end

    # Get the profile of the connections user
    def get_user_profile
      call(:get, '/users/profile')
    end

    # A cached version of the current connections user profile
    def current_user
      @current_user ||= get_user_profile
    end

    # Get profile of a user
    def get_users(id)
      call(:get, "/users/#{id}")
    end

    # Get presence information of a user
    def get_users_presence(id)
      call(:get, "/users/#{id}/presence")
    end

    private

    def call(method, path, payload = {}, headers = {})
      response = connection.send(method) do |req|
        req.url build_api_uri(path)
        req.options.timeout = @timeout
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{access_token}"
        case method
        when :post
          req.body = payload.to_json
          req.headers['Content-Type'] = 'application/json'
        when :get, :delete
          req.params = payload
        end
      end
      return JSON.parse(response.body) if response.success?
    end
  end
end

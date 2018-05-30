require 'circuit_client'
require 'getoptlong'
require 'yaml'

module CircuitClient
  class SendMessageCli
    class Config
      DEFAULTS = {
        timeout: 60,
        host: 'eu.yourcircuit.com',
        client_id: nil,
        client_secret: nil,
        auth_scope: 'ALL'
      }

      def self.load_config(path)
        @@data = YAML.load_file(path)
      end

      def self.method_missing(method_name)
        if DEFAULTS.has_key?(method_name)
          @@data[method_name.to_s] || DEFAULTS[method_name]
        else
          super
        end
      end
    end

    def initialize
      @trace = false
      @list = false
      @new = false
      @participants = []
      @config_file = '/etc/send-circuit.yaml'
      @topic = ''
    end

    def usage
      puts <<-END_USAGE
Usage: send-circuit [OPTIONS]
  --help | -h                display this help text
  --config | -c <file>       path to configuration file
                             (default: /etc/send-circuit.yaml)
  --trace                    print http debug information

List conversations:
  --list | -l                list conversations of user

Send message:
  --subject | -s <text>      Set subject for message

  --conversation | -c <id>   Id of the conversation to send a message to
  or
  --new | -n                 creates a new conversation
  --topic | -t <text>        topic of the new conversation
  --participant | -p
    <email or id>            adds a participant to the conversation


The command will read the message body from stdin.
END_USAGE
    end

    def getopts
      opts = GetoptLong.new(
        ['--help', '-h', GetoptLong::NO_ARGUMENT],
        ['--conversation', '-c', GetoptLong::REQUIRED_ARGUMENT],
        ['--subject', '-s', GetoptLong::REQUIRED_ARGUMENT],
        ['--topic', '-t', GetoptLong::REQUIRED_ARGUMENT],
        ['--trace', GetoptLong::NO_ARGUMENT],
        ['--list', '-l', GetoptLong::NO_ARGUMENT],
        ['--new', '-n', GetoptLong::NO_ARGUMENT],
        ['--participant', '-p', GetoptLong::REQUIRED_ARGUMENT],
        ['--config', '-f', GetoptLong::REQUIRED_ARGUMENT],
      )
      opts.each do |opt, arg|
        case opt
        when '--help'
          usage
          exit 0
        when '--conversation'
          @conversation = arg.to_s
        when '--subject'
          @subject = arg.to_s
        when '--trace'
          @trace = true
        when '--list'
          @list = true
        when '--new'
          @new = true
        when '--participant'
          @participants << arg.to_s
        when '--config'
          @config_file = arg.to_s
        when '--topic'
          @topic = arg.to_s
        end
      end
    end

    def run
      getopts
      Config.load_config(@config_file)

      if @list == true
        list_conversations
        exit 0
      end

      # read msg from stdin
      body = $stdin.readlines.join

      if @new == true
        puts 'creating new group conversation...'
        conv = client.create_group_conversation(@participants, @topic)['convId']
      else
        conv = @conversation
      end

      options = {}
      options[:subject] = @subject unless @subject.nil?
      puts "sending message to #{conv}..."
      begin
        client.create_message(conv, body, **options)
      rescue CircuitClient::ClientError => e
        puts "Could not send message: #{e.message}"
        exit 1
      end
    end

    def client
      CircuitClient::Client.new do |c|
        c.host = Config.host
        c.client_id = Config.client_id
        c.client_secret = Config.client_secret
        c.trace = @trace
        c.timeout = Config.timeout
      end
    end

    def list_conversations
      client.list_conversations.each do |c|
        puts "- #{c['topic']} (#{c['convId']})"
      end
    end
  end
end

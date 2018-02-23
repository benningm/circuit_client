[![Gem Version](https://badge.fury.io/rb/circuit_client.svg)](https://badge.fury.io/rb/circuit_client)

# Circuit Client

circuit\_client is a minimal client for the Circuit REST API.

* [Circuit](https://www.circuit.com/)
* [Circuit REST API](https://circuitsandbox.net/rest/v2/swagger/ui/index.html)

It is not a full-featured API client and current only supports:

 * only client\_credentials authentication
 * list and create conversations
 * create new messages

## API Documentation

Available at [rubydoc.info](http://www.rubydoc.info/gems/circuit_client).

## Usage

### Basic usage

```ruby
require 'circuit_client'

client = CircuitClient::Client.new do |c|
  c.client_id = '<client_id>'
  c.client_secret = '<client_secret>'
end

client.create_message('<convId>', 'Hello World!')
```

## Command line interface

The `send-circuit` command shipped with circuit\_client has the following options:

```
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
```

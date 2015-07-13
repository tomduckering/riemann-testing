require 'socket'
require 'json'

class FakeLogstashServer
  
  attr_reader :port, :responses
  
  def initialize(port: 5665, silent: true)
    @port = port
    @responses = []
    @tcp_server = nil
    @silent = silent
  end
  
  def reset_responses
    puts "Resetting responses gathered by the fake logstash server" unless @silent
    @responses = []
  end
  
  def start(blocking: false)
    @tcp_server = TCPServer.new @port

    main_thread = Thread.start do
      puts "Starting a fake logstash server..." unless @silent
      loop do
        puts "Waiting for connection on port #{@port}" unless @silent
        Thread.start(@tcp_server.accept) do |client|    # Wait for a client to connect
          puts "Got connection from: #{client.to_s}" unless @silent
          while line = client.gets # Read lines from socket
            puts "Recieved: #{line}" unless @silent
            responses << JSON.parse(line,{symbolize_names: true})
          end
          client.close
        end
      end
    end
    main_thread.join if blocking
  end
end

if __FILE__ == $0
  puts "Being run directly..."
  server = FakeLogstashServer.new(silent: false)
  server.start(blocking: true)
end

$: << "lib" << "../lib"

# Simple Hello, World! server.
#
# It does nothing interesting and, in fact, it looks just like a
# regular HTTP server.
#
# (1) start the SPDY eventmachine server
# > ruby hello_world.rb
#
# (2) start Chrome and force it to use SPDY over SSL.
#
# This is done by passing --use-spdy=ssl in the command line. This
# forces SPDY on HTTPS connections.
#
# (3) visit https://localhost:10000/

require "eventmachine"
require "spdy"

class HelloWorld < EM::Connection
  def post_init
    # Create the SPDY parser. This will handle all the SPDY events.
    @parser = SPDY::Parser.new

    # For this simple server, this is the only event we care about.
    #
    # stream_id stream ID sent by the client. An always increasing ODD
    # number.
    # assoc_stream associated stream ID. Used in bidirectional
    # communication with the client.
    # priority TODO I don't know what it does.
    # headers a Hash of headers sent in the request.
    @parser.on_headers_complete do |stream_id, assoc_stream, priority, headers|
      # SPDY receives a SYN_STREAM and then it should respond with a
      # SYN_REPLY packet.
      syn_reply = SPDY::Protocol::Control::SynReply.new(:zlib_session => @parser.zlib_session)

      # Response headers.
      headers = {
        "Content-Type" => "text/plain",
        "status"       => "200 OK",
        "version"      => "HTTP/1.1"
      }
      content = "Hello, World! I'm a simple SPDY server!"

      # Create and send response headers.
      # Notice that SPDY sends two packets for headers and
      # content. This might make no sense now, but it is vital for
      # server push.
      # Also note that SPDY is a binary protocol, so a binary string
      # needs to be sent.
      send_data syn_reply.create(:stream_id => stream_id, :headers => headers).to_binary_s

      # Now send the data packet. As in the previous packet, stream_id
      # identifies the request this response belongs to.
      data = SPDY::Protocol::Data::Frame.new
      send_data data.create(:stream_id => stream_id, :data => content).to_binary_s

      # Finalize response by sending a FIN packet, which is an empty
      # data packet with a flags value of 1.
      fin = SPDY::Protocol::Data::Frame.new
      send_data fin.create(:stream_id => stream_id, :flags => 1).to_binary_s
    end

    # Start Transport Layer Security, in other words, enable secure
    # connections.
    start_tls
  end

  def receive_data data
    # Feed the data to the parser and call
    @parser << data
  end

  def unbind
    # SPDY uses Zlib compression to faster data transmission. This
    # Zlib session needs to be reseted when the request and response
    # are done.
    @parser.zlib_session.reset
  end
end

EM.run do
  EM.start_server "0.0.0.0", 10000, HelloWorld
end

$: << "lib" << "../lib"

# Simple SPDY server.
#
# This server is nothing spectacular, just a server that kind of
# mimics a regular HTTP server, sending the requested file, one per
# connection.
#
# (1) start the SPDY eventmachine server
# > ruby simple_server.rb
#
# (2) start Chrome and force it to use SPDY over SSL.
#
# This is done by passing --use-spdy=ssl in the command line. This
# forces SPDY on HTTPS connections.
#
# (3) visit https://localhost:10000/

require "eventmachine"
require "spdy"
require "tilt"
require "rack/mime"

class SimpleServer < EM::Connection
  def post_init
    @parser = SPDY::Parser.new

    @parser.on_headers_complete do |stream_id, assoc_stream, priority, headers|
      puts "GET #{headers['url']}"

      # Basic routing
      file = if headers["url"] == "/"
               "index.html"
             else
               headers["url"][1..-1]
             end

      # Change directory context for sending files
      Dir.chdir "public/" do
        send_file stream_id, file
      end
    end

    # Start Transport Layer Security, in other words, enable secure
    # connections.
    start_tls
  end

  # Send the requested file through the given stream ID
  def send_file stream_id, file
    res_headers = { "status" => "200 OK", "version" => "HTTP/1.1" }
    res_headers["Content-Type"] = Rack::Mime.mime_type File.extname(file)

    # File contents
    data = if File.exists? file
             File.binread(file)
           elsif File.exists? "#{file}.erb"
             Tilt.new("#{file}.erb").render
           else
             res_headers["Content-Type"] = "text/plain"
             res_headers["status"]       = "404 Not Found"

             "404 Not Found"
           end

    res_headers["Content-Length"] = data.size.to_s

    # Create response stream.
    # See hello_world.rb for detailed SPDY protocol instructions.
    syn_reply = SPDY::Protocol::Control::SynReply.new zlib_session: @parser.zlib_session

    # Send headers.
    send_data syn_reply.create(stream_id: stream_id, headers: res_headers).to_binary_s

    # Send contents.
    send_data SPDY::Protocol::Data::Frame.new.create(stream_id: stream_id, data: data).to_binary_s

    # Finalize response.
    fin = SPDY::Protocol::Data::Frame.new
    send_data fin.create(stream_id: stream_id, flags: 1).to_binary_s
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
  EM.start_server "0.0.0.0", 10000, SimpleServer
end

$: << "lib" << "../lib"

# Simple SPDY server with Server Push.
#
# This server takes advantage of SPDY Server Push feature, pushing
# resources to the browser when the HTML page is requested.

# This simple server always pushes resources, even though they might
# already be on the browser's cache. It is only for demonstrational
# purposes.
#
# (1) start the SPDY eventmachine server
# > ruby push_server.rb
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

class PushServer < EM::Connection
  def post_init
    @parser = SPDY::Parser.new

    @parser.on_headers_complete do |stream_id, assoc_stream, priority, headers|
      puts "GET #{headers['url']}"

      # Change directory context for sending files
      Dir.chdir "public/" do
        # Basic routing
        if headers["url"] == "/"
          send_html_with_push stream_id
        else
          file = headers["url"][1..-1]

          send_file stream_id, file
        end
      end
    end

    # Start Transport Layer Security, in other words, enable secure
    # connections.
    start_tls
  end

  def receive_data data
    @parser << data
  end

  def unbind
    @parser.zlib_session.reset
  end

  # Send the requested file through the given stream ID
  def send_file stream_id, file
    res_headers = { "status" => "200 OK", "version" => "HTTP/1.1" }
    res_headers["Content-Type"] = Rack::Mime.mime_type File.extname(file)

    data = if File.exists? file
             File.binread(file)
           else
             res_headers["Content-Type"] = "text/plain"
             res_headers["status"]       = "404 Not Found"

             "404 Not Found"
           end

    res_headers["Content-Length"] = data.size.to_s

    syn_reply = SPDY::Protocol::Control::SynReply.new zlib_session: @parser.zlib_session
    send_data syn_reply.create(stream_id: stream_id, headers: res_headers).to_binary_s
    send_data SPDY::Protocol::Data::Frame.new.create(stream_id: stream_id, data: data).to_binary_s

    fin = SPDY::Protocol::Data::Frame.new
    send_data fin.create(stream_id: stream_id, flags: 1).to_binary_s
  end

  # Send the HTML file and pushes all the images
  def send_html_with_push stream_id
    # Grab the HTML
    html = Tilt.new("index.html.erb").render

    # Set HTML headers
    html_headers = {
      "status"       => "200 OK",
      "version"      => "HTTP/1.1",
      "Content-Type" => "text/html"
    }

    # Initiate the response stream
    syn_reply = SPDY::Protocol::Control::SynReply.new zlib_session: @parser.zlib_session
    send_data syn_reply.create(stream_id: stream_id, headers: html_headers).to_binary_s

    # Create server push stream, associated to the request stream
    syn_stream = SPDY::Protocol::Control::SynStream.new zlib_session: @parser.zlib_session
    syn_stream.associated_to_stream_id = stream_id

    # Send all the images
    Dir["images/*.jpg"].each_with_index do |img, i|
      # Server push stream ID is an increasing EVEN number
      res_stream_id = 2 * (i + 1)

      # Image headers
      img_headers = {
        "status"  => "200",
        "version" => "HTTP/1.1",
        "url"     => "https://localhost:10000/#{img}",
        "content-type" => Rack::Mime.mime_type(File.extname(img))
      }

      # Send headers
      send_data syn_stream.create(flags: 2, stream_id: res_stream_id, headers: img_headers).to_binary_s

      # Send data
      send_data SPDY::Protocol::Data::Frame.new.create(stream_id: res_stream_id, data: File.binread(img)).to_binary_s

      # End response
      send_data SPDY::Protocol::Data::Frame.new.create(stream_id: res_stream_id, flags: 1).to_binary_s
    end

    # Send HTML
    send_data SPDY::Protocol::Data::Frame.new.create(stream_id: stream_id, data: html).to_binary_s

    # Finish response
    fin = SPDY::Protocol::Data::Frame.new
    send_data fin.create(stream_id: stream_id, flags: 1).to_binary_s
  end
end

EM.run do
  EM.start_server "0.0.0.0", 10000, PushServer
end

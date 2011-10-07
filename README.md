# Ruby SPDY examples

Collection of simple Ruby SPDY servers, based on the [`spdy` gem from
Ilyia Grigorik](https://github.com/igrigorik/spdy) and the wonderful
[SPDY Book](http://spdybook.com/) as a reference.

## Requirements

I've tested this on Ruby 1.9.2 and 1.9.3.

You need to install
[EventMachine](https://github.com/eventmachine/eventmachine) to run
this examples and, of course, the SPDY gem:

    gem install eventmachine
    gem install spdy

Some of the advanced examples rely on external gems, in order to do so
install the following if you haven't already:

    gem install tilt
    gem install rack

If you use [RVM](https://rvm.beginrescueend.com/) you can simply
execute the following to install all the required gems:

    rvm import required.gems

## Running the examples

All these examples are easily run as a Ruby script:

    ruby server_name.rb

Replace `server_name.rb` with the server you like to try.

In order to see this servers you'll need to instruct Google Chrome /
Chromium to use SPDY over HTTPS connections. This is done using the
`--use-spdy=ssl` command line parameter.

All the servers listen on the same port, so point your browser to
[https://localhost:10000/](https://localhost:10000/). It is important
to know that you need to use HTTPS, not HTTP.

If you'd like to see what's going on, and this is highly recommended,
you can open in a new tab [Chrome's network
internals](about:net-internals) and in enter in the *Events* tab the
following query:

    type:SPDY_SESSION is:active

I personally **highly recommend** to install [Google's Speed
Tracer](https://chrome.google.com/webstore/detail/ognampngfcbddbfemdapefohjiobgbdl?hl=en-US&hc=search&hcp=main)
extension. Once this is done you need to run Chrome with the following
command line flag to enable the Timeline API:

    --enable-extension-timeline-api

## Included servers

### `hello_world.rb`

Obligatory Hello, World! server to demonstrate a super simple SPDY
session.

# Ruby SPDY examples

Collection of simple Ruby SPDY servers, based on the [`spdy` gem from
Ilyia Grigorik](https://github.com/igrigorik/spdy) and the wonderful
[SPDY Book](http://spdybook.com/) as a reference.

## Why use SPDY?

There are two main reasons to use SPDY

### Security

Since the raising of browser extensions that eases hijacking of HTTP
sessions two things became clear: HTTP session was far from perfect
and everybody should be using secure connections. Some major sites
like Google and GitHub began to serve all their pages, at least for
authenticated users, in HTTPS. SPDY **always** runs over SSL, which
makes it secure by default.

**Use HTTPS, or better yet, use SPDY with HTTPS fallback.**

### Speed

Quoting SPDY Book:

> SPDY is not optimized for very small applications.

This doesn't mean that you shouldn't be using SPDY, but just to have
in mind that SPDY will probably not perform faster for very small
applications. But if your application deals with lots of resources
then SPDY might outperform your web application. And using SPDY
features like Server Push might greatly outperform your previous
application.

Google already had SPDY enabled for their sites if you use
Chrome. Firefox is going to implement SPDY in their next release, and
Amazon began delivering content through SPDY to their new Kindle. The
future needs faster and secure web access, and SPDY provides all that
out of the box.

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

### `simple_server.rb`

Simple server that kind of mimics a regular HTTP server, sending the
requested file, one per connection.

### `push_server.rb`

Now we're talking. This server implements one of the most interesting
features of SPDY: [Server
Push](http://www.chromium.org/spdy/link-headers-and-server-hint). As
the official documentation says:

> Server Push is where the server pushes a resource directly to the
> client without the client asking for the resource.  The server is
> making an assumption here that pushing the resource is desirable.
> Pushing a cacheable resource can be risky, as the browser might
> already have the resource and the push can be redundant.

This simple server always pushes resources, even though they might
already be on the browser's cache. It is only for demonstrational
purposes.

# TODO

* Add POST examples.
* Implement a server that negotiates SPDY & HTTP/1.1 in order to offer
  fallback for browsers that do not implement SPDY.  I'm guessing the
  best options is switching to
  [Carson McDonald's EventMachine fork](https://github.com/carsonmcdonald/eventmachine)
  until the mantainers of EventMachine merge his
  [pull request](https://github.com/eventmachine/eventmachine/pull/196)
  for NPN negotiation.
* Create framework for easier for stream creation.

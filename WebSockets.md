# Web Sockets #

## History ##

A few years ago I came up with the idea of bringing sockets to the web via an Ajax proxy. (sometime before [March '06](http://xantus.vox.com/library/post/codename-shortbus.html))  So I started a little project called Shortbus.  The scope of that project grew quickly from being a web socket proxy to an event bus.  I joined up with Alex Russell of Dojo toolkit and Greg Wilkins of Jetty, and we renamed that project to Cometd.   I later revived that original idea of creating a web socket library, and built the necessary pieces for WebSockets.  Sprocket, the server framework.  Sprocket.Gateway, the Sprocket HTTP plugin that proxies connections, and Sprocket.Socket the JavaScript library that connects the browser to Sprocket.Gateway.

## Sprocket ##

Sprocket is a Perl networking library based on POE. It has support for highly efficient and scalable event loop [libev](http://software.schmorp.de/pkg/libev.html) (POE::Loop::EV)  With this, Sprocket can handle thousands of connections.  Sprocket has handled upwards of 20,000 connections on one server.

## Sprocket.Gateway ##

Sprocket.Gateway is subclass of the HTTP plugin available with Sprocket.  It can serve files extremely fast with the use of IO::AIO, and handle gateway requests at the same time.  An ACL is used to prevent unauthorized connections to hosts through the gateway.

## Sprocket.Socket ##

Sprocket.Socket is a JavaScript library that provides a socket interface for client side applications.  Currently there is an [Extjs](http://extjs.com/) implementation (Ext.ux.Sprocket.Socket), but it is relatively easy to port.  Sprocket.Socket, unlike some web socket libraries, supports multiple sockets simultaneously via a single long polling Xmlhttp or JSONP connection pair.  One connection is used for long polling or JSONP, and the other is used to send quick responses while leaving the other connection to wait for data.  This method provides millisecond response times.

## Proof of Concept ##

[Comet Desktop](http://cometdesktop.com/)

A jabber client and an IRC client has been built with Extjs and is hosted in a web desktop environment.  The browser parses the IRC protocol and the XMPP protocol on the client side.  This allows Sprocket.Gateway to only proxy the data, without needing to know what type of stream it is.  Unlike BOSH which is primarily for XMPP.

## Data Framing ##

Proper data framing is necessary when dealing with data over sockets.  And WebSockets are no exception.

### The problem ###

Consider this.  If the data that the client expects is split into lines (\n or \x0A):

```
  This is a test\n
  Foo bar baz\n
  Just another Perl Hacker\n
```

If one of those lines ends up on the end of a network frame, the client may receive:

```
  This is a test\n
  Foo bar baz\n
  Just another
```

and then

```
 Perl Hacker\n
```

If you don't account for this then you will end up with odd inconsistencies.  Generally, JavaScript web programmers aren't accustomed to this problem since they deal with Ajax requests that return full blocks of data.

### The solution ###

Data framing filters!

## Data Framing Filters ##

You put data into an object, and zero or more full blocks of data are returned.  It sounds simple, and is, somewhat.  I used a familiar system, from [POE](http://poe.perl.org/), that brings the power of tried and true code from a Perl project, to JavaScript.

Currently, there are several filters available.  They are written for the Extjs toolkit, but they can be easily be written to be framework agnostic. (See [js.io](http://js.io/))

  * [Ext.ux.Sprocket.Filter](http://xant.us/ext-ux/lib/Sprocket/Filter.js) - The base class for all filters
  * [Ext.ux.Sprocket.Filter.Stream](http://xant.us/ext-ux/lib/Sprocket/Filter.js) - A simple filter, nothing is buffered.  It is usually used as a placeholder in the absence of another filter.
  * [Ext.ux.Sprocket.Filter.Line](http://xant.us/ext-ux/lib/Sprocket/Filter/Line.js) - A line type auto detecting filter.  Supports most types of line combinations (\x0D\x0A?|\x0A\x0D?|\u2028) with the added benefit of being a delimiter splitting filter.  You can specify anything as your delimiter.
  * [Ext.ux.Sprocket.Filter.JSON](http://xant.us/ext-ux/lib/Sprocket/Filter/JSON.js) - A JSON filter.  JSON goes in, objects come out, or objects go in, and JSON comes out.
  * [Ext.ux.Sprocket.Filter.Stackable](http://xant.us/ext-ux/lib/Sprocket/Filter.js) - The beauty of using data framing filters starts here.  You can stack any number of filters in any order, and magic comes out.  See the next section.

## Stackable Filters ##

Consider this set of stacked filters:

```
  var stack = new Ext.ux.Sprocket.Filter.Stackable({
      filters: [
           new Ext.ux.Sprocket.Filter.Line(),
           new Ext.ux.Sprocket.Filter.JSON()
      ]
  });
```

That is a line filter filter combined with a JSON filter.  Lines of JSON can be pushed into that filter stack and an array of json objects is returned:

```
  var arrObjs = stack.get('{ "foo": "bar" }\r\n{ "bar": "baz" }\r\n{ "blitz": "boom" }\r\n');
```

arrObjs is now an Array of 3 Objects.  (The line filter detected that \r\n is the line break, and will now split on \r\n from now on.)

```
  var strData = stack.put(arrObjs);
```

strData is now:

```
    '{"foo":"bar"}\r\n{"bar":"baz"}\r\n{"blitz":"boom"}';
```

The stacked filters chain into each other both ways!  There is also an interface for pushing, shifting, unshifting and popping filters on the fly.

BTW, you're not restricted to using these filters just for socket data.  There are other uses for stackable filters.
# easy signaling

## What is this?

WebRTC Signaling with as few complexity as possible. It is compatible with
[rtc-lib](https://github.com/Innovailable/rtc-lib). You can use the signaling
server standalone or integrate it in your Node.js project.

## Standalone

Install the package with

    npm install -g easy-signaling

To use the signaling server in standalone mode simply run

    easy-signaling

You can use the environment variables `BIND_PORT` (defaults to 8080) and
`BIND_HOST` (defaults to 0.0.0.0) to configure the listening socket of the
server. A websocket server will be listening on the specified port and provide
signaling to clients.

## Library

If you want to include the server in your project install add the dependency
'easy-signaling' to your package.json.

You can either use a `Hotel` to provide multiple rooms ...

    var hotel = new require("easy-signaling").Hotel()
    hotel.create_guest(connection, "room_name")

... or use `Room` if you need only one room ...

    var room = new require("easy-signaling").Room()
    room.create_guest(connection)

The `connection` object in the examples is a `Channel` implementing the
connectino to the client. You can implement your own `Channel` or use
`WebsocketChannel` which is a wrapper around WebSockets provided by the `ws`
library.

The complete documenation is available
[here](http://innovailable.github.io/easy-signaling/).

# easy signaling

## What is this?

WebRTC Signaling with as few complexity as possible. It is compatible with
[palava-client](https://github.com/palavatv/palava-client). You can use the
signaling server standalone or integrate it in your Node.js project.

## Standalone

Install the package with

    npm install -g easy-signaling

To use the signaling server in standalone mode simply run

    easy-signaling

You can use the environment variables `BIND_PORT` (defaults to 8080) and
`BIND_HOST` (defaults to 0.0.0.0) to configure the listening socket of the
server. A websocket server will be listening on the specified port and provide
signaling to clients using the [palava
protocol](https://github.com/palavatv/palava-client/wiki/Protocol).

## Library

If you want to include the server in your project install add the dependency
'easy-signaling' to your package.json.

The central element of the signaling server is called `Hotel`. It contains
`Room`s which contain `Guest`s. To create a `Hotel` simply type something like
this

    var hotel = new require("easy-signaling").Hotel()

To add a `Guest` to the `Hotel` do

    hotel.create_guest(connection)

`connection` should be a communication channel with the client. The client has
to speak the [palava
protocol](https://github.com/palavatv/palava-client/wiki/Protocol). The
`connection` object has to emit the events `message` and `close`, might emit
the 'error' event and  has to support the method `send(data)`. The messages
given to `send()` and expected from `message` are native JavaScript objects.
You might have to encode and decode JSON in your channel. See `src/main.coffee`
for an example.

The `Guest` might join a room if it receives a `join_room` message from the
client. You do not have to do anything else on the server side to make
signaling work. Clients in the same room will communicate with each other.


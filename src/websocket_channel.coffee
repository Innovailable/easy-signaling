EventEmitter = require('events').EventEmitter

###*
# A signaling channel using WebSockets. Wraps around `ws` WebSockets. Reference implementation of a channel.
# @class WebsocketChannel
# @extends events.EventEmitter
#
# @constructor
# @param {WebSocket} ws The websocket connection with the client
#
# @example
#     // using only one Room
#
#     var es = require('easy-signaling');
#     var ws = require('ws')
#
#     var wss = new ws.WebSocketServer({port: 8080, host: '0.0.0.0'})
#     var room = new es.Room();
#
#     wss.on('connection', function(ws) {
#       channel = new es.WebsocketChannel(ws);
#       room.create_guest(channel);
#     });
#
# @example
#     // using Hotel to support multiple rooms based on the URL
#
#     var es = require('easy-signaling');
#     var ws = require('ws')
#
#     var wss = new ws.WebSocketServer({port: 8080, host: '0.0.0.0'})
#     var hotel = new es.Hotel();
#
#     wss.on('connection', function(ws) {
#       channel = new es.WebsocketChannel(ws);
#       hotel.create_guest(channel, ws.upgradeReq.url);
#     });
###
class exports.WebsocketChannel extends EventEmitter

  ###*
  # A message was received
  # @event message
  # @param {Object} data The decoded message
  ###

  ###*
  # The WebSocket was closed
  # @event closed
  ###

  ###*
  # An error occured with the WebSocket
  # @event error
  # @param {Error} error The error which occured
  ###

  constructor: (@ws) ->
    @ws.on 'message', (msg) =>
      try
        data = JSON.parse(msg)
        @emit('message', data)
      catch err
        @emit('error', "Error processing incoming message: " + err.message)

    @ws.on 'close', () =>
      @emit('closed')

  ###*
  # Send data to the client
  # @method send
  # @param {Object} data The message to be sent
  ###
  send: (data) ->
    msg = JSON.stringify(data)
    @ws.send(msg)

  ###*
  # Close the connection to the client
  # @method close
  ###
  close: () ->
    @ws.close()

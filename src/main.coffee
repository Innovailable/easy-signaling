#!/usr/bin/env coffee
###############################################################################
#
#  easy-signaling - A WebRTC signaling server
#  Copyright (C) 2014  Stephan Thamm
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

logger = require('log4js').getLogger()
EventEmitter = require('events').EventEmitter

BIND_PORT = process.env.BIND_PORT ? 8080
BIND_HOST = process.env.BIND_HOST ? "0.0.0.0"

WebSocketServer = require('ws').Server
Hotel = require('./signaling').Hotel

class WebsocketChannel extends EventEmitter

  constructor: (@ws) ->
    @ws.on 'message', (msg) =>
      try
        data = JSON.parse(msg)
        @emit('message', data)
      catch err
        @emit('error', "Error processing incoming message: " + err.message)

    @ws.on 'close', () =>
      @emit('close')

  send: (data) ->
    msg = JSON.stringify(data)
    @ws.send(msg)

  close: () ->
    @ws.close()

# start doing stuff ...
hotel = new Hotel()
wss = new WebSocketServer({port: BIND_PORT, host: BIND_HOST})

logger.info("Starting server on '" + BIND_HOST + ":" + BIND_PORT + "'")

wss.on 'connection', (ws) ->
  logger.debug("Accepting connection")
  channel = new WebsocketChannel(ws)
  room = ws.upgradeReq.url
  hotel.create_guest(channel, room)


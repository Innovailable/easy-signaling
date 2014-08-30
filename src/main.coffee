WebSocketServer = require('ws').Server
Hotel = require('./signaling').Hotel

# start doing stuff ...
hotel = new Hotel()
wss = new WebSocketServer({port: 8080})

wss.on 'connection', (ws) ->
  hotel.create_guest(ws, hotel)


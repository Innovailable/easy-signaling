signaling = require('./signaling')

module.exports = {
  Hotel: signaling.Hotel
  Room: signaling.Room
  Guest: signaling.Guest
  WebsocketChannel: require('./websocket_channel').WebsocketChannel
}

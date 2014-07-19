#!/usr/bin/env coffee

uuid = require('node-uuid')

WebSocketServer = require('ws').Server
EventEmitter = require('events').EventEmitter

logger = require('log4js').getLogger()

is_empty = (obj) ->
  for _, _ of obj
    return false

  return true


class Hotel

  constructor: () ->
    @rooms = {}


  get_room: (name) ->
    return @rooms[name]


  create_room: (name) ->
    if @rooms[name]?
      logger.error("Trying to create room which already exists")
      return

    logger.debug("Creating room '" + name + "'")

    room = @rooms[name] = new Room(this)

    room.on 'empty', () =>
      logger.debug("Cleaning up room '" + name + "'")
      delete @rooms[name]

    return room


class Room extends EventEmitter

  constructor: () ->
    @guests = {}


  broadcast: (msg, sender) ->
    for id, guest of @guests
      if guest.id != sender
        guest.send(msg)


  send: (msg, receiver) ->
    @guests[receiver]?.send(msg)


  join: (guest) ->
    @guests[guest.id] = guest


  leave: (guest) ->
    if not @guests[guest.id]?
      logger.error("Guest is trying to leave without being in the room")
      return

    delete @guests[guest.id]

    if is_empty(@guests)
      @emit 'empty'


class Guest extends EventEmitter

  constructor: (@ws, @hotel) ->
    @id = uuid.v4()
    ws.on 'message', (data, flags) => @receive(data, flags)
    ws.on 'close', () => @closing()


  receive: (msg, flags) ->
    try
      data = JSON.parse(msg)
    catch
      @error("Error parsing incoming message: " + data)
      return

    if not data.event?
      @error("Incoming message does not include event")
      return

    switch data.event
      when 'join_room'
        if not data.room_id?
          @error("'join_room' is missing room id")
          return

        # leave if already in a room
        if @room then @room.leave(this)

        # save status
        @status = data.status or {}

        # find room
        @room = @hotel.get_room(data.room_id)
        if not @room
          @room = @hotel.create_room(data.room_id)

        # tell new guest
        @send {
          event: 'joined_room'
          own_id: @id
          peers: ({ peer_id: id, status: guest.status } for id, guest of @room.guests)
        }

        # get in
        @room.join(this)

        # tell everyone else
        @room.broadcast {
          event: 'new_peer'
          peer_id: @id
          status: @status
        }, @id

      when 'send_to_peer'
        if not data?.peer_id or not data?.data?.event
          @error("'send_to_peer' is missing a mandatory value")
          return

        if not @room?
          @error("Attempted 'send_to_peer' without being in a room")
          return

        if data.event in ['peer_left', 'new_peer', 'joined_room', 'error']
          @error("Trying to send privileged command with 'send_to_peer'")
          return

        # get and modify payload ... ugly!
        payload = data.data
        payload.sender_id = @id

        # pass on
        @room.send(payload, data.peer_id)


  send: (data) ->
    msg = JSON.stringify(data)
    @ws.send(msg)


  error: (msg) ->
    # tell client
    @send {
      event: 'error'
      message: msg
    }

    # tell log
    logger.error(msg)

    # end it all
    @ws.close()


  closing: () ->
    @room?.broadcast {
      event: 'peer_left'
      sender_id: @id
    }, @id

    @room?.leave(this)


# start doing stuff ...
hotel = new Hotel()
wss = new WebSocketServer({port: 8080})
wss.on 'connection', (ws) ->
  new Guest(ws, hotel)


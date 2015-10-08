{Hotel, Room, Guest} = require('../../src/signaling')
{EventEmitter} = require('events')
sinon = require('sinon')

class TestChannel extends EventEmitter

  constructor: () ->
    @incoming = []
    @closed = false

  send_test: (msg) ->
    @emit('message', msg)

  recv_test: () ->
    if @incoming.length > 0
      return @incoming.shift()
    else
      throw new Error("No message received")

  send: (msg) ->
    @incoming.push(msg)

  empty: () ->
    return @incoming.length == 0

  close: () ->
    @closed = true


class TestGuest extends EventEmitter
  constructor: (@id) ->


describe 'Hotel', () ->

  hotel = null
  room = null
  room_name = null
  beforeEach () ->
    hotel = new Hotel()
    room_name = 'test room'
    room = hotel.get_room(room_name)

  describe 'room management', () ->

    it 'should remove the room from the hotel and trigger the room_removed event', () ->
      spy = sinon.spy()
      hotel.on 'room_removed', spy
      room.emit("empty")
      hotel.rooms.should.not.contain.keys(room_name)
      spy.calledOnce.should.be.true

    it 'should add and remove correct amount of rooms and trigger all corresponding events', () ->
      add_spy = sinon.spy()
      remove_spy = sinon.spy()
      hotel.on 'room_created', add_spy
      hotel.on 'room_removed', remove_spy
      room_1 = hotel.get_room('1')
      room_2 = hotel.get_room('2')
      room_3 = hotel.get_room('3')
      hotel.rooms.should.contain.keys('1', '2', '3', 'test room')
      room_1.emit("empty")
      room_2.emit("empty")
      room_3.emit("empty")
      room.emit("empty")
      hotel.rooms.should.be.empty
      add_spy.callCount.should.equal(3)
      # one more removed because one room is created on test initialisation
      remove_spy.callCount.should.equal(4)

    it 'should create a room with the correct name, add it to rooms and trigger the room_created event', () ->
      spy = sinon.spy()
      hotel.on 'room_created', spy
      room_t = hotel.get_room('trigger')
      room_t.name.should.equal('trigger')
      spy.calledOnce.should.be.true
      hotel.rooms.should.contain.keys('trigger')


describe 'Room', () ->
  room_name = 'test room'
  room = null
  beforeEach () ->
     room = new Room(room_name)

  it 'should contain the previously added guest', () ->
    channel_1 = new TestChannel()
    channel_2 = new TestChannel()
    guest_a = room.create_guest(channel_1)
    guest_b = room.create_guest(channel_2)
    channel_1.send_test({"type": "join"})
    channel_2.send_test({"type": "join"})
    room.guests[guest_a.id].should.equal(guest_a)
    room.guests[guest_b.id].should.equal(guest_b)

  it 'should send to all other guests on broadcast', () ->
    guest_a = new TestGuest('a')
    guest_b = new TestGuest('b')
    guest_c = new TestGuest('c')

    guest_a.send = sinon.spy()
    guest_b.send = sinon.spy()
    guest_c.send = sinon.spy()

    message = {type: 'ping'}

    room.join(guest_a).should.be.true
    room.join(guest_b).should.be.true
    room.join(guest_c).should.be.true

    room.broadcast(message, guest_a.id)

    guest_a.send.callCount.should.be.equal(0)
    guest_b.send.calledOnce.should.be.true
    guest_b.send.calledWith(message).should.be.true
    guest_c.send.calledOnce.should.be.true
    guest_c.send.calledWith(message).should.be.true

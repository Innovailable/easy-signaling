es = require('../../src/lib')
WebSocket = require('ws')
Q = require('q')
keys = require('object-keys')

PORT=6578

class TestWebSocket

  constructor: () ->
    @closed = true
    @incoming = []

  connect: () ->
    if not @connect_promise?
      @ws=new WebSocket('ws://localhost:' + PORT)

      @ws.on 'message', (raw) =>
        if @recv_defer?
          defer = @recv_defer
        else
          defer = Q.defer()
          @incoming.push(defer.promise)

        try
          defer.resolve(JSON.parse(raw))
        catch err
          defer.reject(err)

      connect_defer = Q.defer()
      @connect_promise = connect_defer.promise

      @ws.on 'open', () ->
        connect_defer.resolve()

      @ws.on 'closing', () =>
        @closed = true

    return @connect_promise

  send: (data) ->
    @connect().then () =>
      return Q.ninvoke(@ws, 'send', JSON.stringify(data))

  recv: () ->
    if @incoming.length > 0
      return @incoming.shift()
    else
      @recv_defer = Q.defer()
      return @recv_defer.promise

  sendRecv: (data) ->
    return @send(data).then () =>
      return @recv()

  close: () ->
    @ws.close()

  empty: () ->
    return @incoming.length == 0


describe 'Integration tests', () ->
  wss = null

  before () ->
    wss = new WebSocket.Server({port: PORT})

  describe 'Hotel', () ->
    hotel = null
    socket = null

    new_connection = (ws) ->
        room = ws.upgradeReq.url
        channel = new es.WebsocketChannel(ws)
        hotel.create_guest(channel, room)

    beforeEach () ->
      hotel = new es.Hotel()
      wss.on('connection', new_connection)

    afterEach () ->
      wss.removeListener('connection', new_connection)

    describe 'joining and leaving', () ->
      it 'should be able to join', () ->
        socket = new TestWebSocket()

        return socket.connect().then () ->
          return socket.sendRecv({type: 'join'})
        .then (res) ->
          res.type.should.equal('joined')

      it 'should be able join and leave two peers', () ->
        socket_a = new TestWebSocket()
        socket_b = new TestWebSocket()

        return socket_a.connect().then () ->
          return socket_a.sendRecv({type: 'join'})
        .then (res) ->
          res.type.should.equal('joined')
          res.peers.should.be.empty
          return socket_b.connect()
        .then () ->
          return socket_b.sendRecv({type: 'join'})
        .then (res) ->
          res.peers.should.not.be.empty
          socket_a.close()
          return socket_b.recv()
        .then (res) ->
          res.type.should.be.equal('peer_left')
          socket_a.closed.should.be.true

    describe 'Status', () ->
      status_a = {a: 23}
      status_b = {b: 42}

      it 'should get status of peers', () ->
        socket_a = new TestWebSocket()
        socket_b = new TestWebSocket()

        return socket_a.connect().then () ->
          return socket_a.sendRecv({type: 'join', status: status_a})
        .then (res) ->
          res.type.should.equal('joined')
          return socket_b.connect()
        .then () ->
          return socket_b.sendRecv({type: 'join', status: status_b})
        .then (res) ->
          res.type.should.equal('joined')

          res.peers.should.not.be.empty
          peer_id = keys(res.peers)
          res.peers[peer_id].should.deep.equal(status_a)

          return socket_a.recv()
        .then (res) ->
          res.type.should.equal('peer_joined')
          res.status.should.deep.equal(status_b)

      it 'should get status updates of peers', () ->
        socket_a = new TestWebSocket()
        socket_b = new TestWebSocket()

        return socket_a.sendRecv({type: 'join'}).then (res) ->
          res.type.should.equal('joined')
          return socket_b.sendRecv({type: 'join', status: status_a})
        .then (res) ->
          res.type.should.equal('joined')
          return socket_a.recv()
        .then (res) ->
          res.type.should.equal('peer_joined')
          res.status.should.deep.equal(status_a)
          return socket_b.send({type: 'status', status: status_b})
        .then () ->
          return socket_a.recv()
        .then (res) ->
          res.type.should.equal('peer_status')
          res.status.should.deep.equal(status_b)


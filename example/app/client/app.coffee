# Client-side Code

# Bind to socket events
SS.socket.on 'disconnect', ->  $('#message').text('SocketStream server is down :-(')
SS.socket.on 'reconnect', ->   $('#message').text('SocketStream server is up :-)')

# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->
  limber = SS.client.limber.limber
  
  console.log "Limber", limber
  
  box1 = new limber.geometry.AABB(1, 1, 1, 1)
  box2 = new limber.geometry.AABB(2, 2, 1, 1)
  
  hull = new limber.geometry.ConvexHull([0, 0], [1, 1], [4, 1], [4, 0])
  
  [axis, dist] = box1.testCollision(box2)
  
  console.log "Restituted", box2.clone().add(axis.scale(dist / 2))
  console.log "Restituted", box1.clone().subtract(axis.scale(dist / 2))
  
  console.log "Hull", hull, hull.getFaceNormals()
  
  console.log box1, box2, box1.testCollision(box2)
  
  engine = new limber.engine.Canvas2D("canvas", 200, 200)
    .attach(new limber.component.FPS("fps"))
    .animate()

  # Make a call to the server to retrieve a message
  SS.server.app.init (response) ->
    $('#message').text(response)

  # Start the Quick Chat Demo
  SS.client.demo.init()
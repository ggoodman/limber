# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->

  limber = SS.client.limber.limber
  
  wall = new limber.geometry.Wall(1, 0, 2)
  square1 = new limber.geometry.AABB(-1, -1, 1, 1)
  square2 = new limber.geometry.AABB(1, 1, 3, 3)
  
  console.log square1.testCollision(wall)
  console.log square2.testCollision(wall)
  console.log wall.testCollision(square1)
  console.log wall.testCollision(square2)
  
  class Entity extends limber.entity.Entity
    randomAcceleration: new limber.trait.RandomAcceleration(5)
    body: new limber.trait.AABBBody(-5, -5, 5, 5)
    flocking: new limber.trait.Flocking
    bounded: new limber.trait.Bounded(0, 0, 800, 600)
    collisionDetection: new limber.trait.CollisionDetection
    collisionResponse: new limber.trait.CollisionResponse
    collisionAvoidance: new limber.trait.CollisionAvoidance
    
    initialize: (@id, pos, vel) ->
      @mixin new limber.trait.Position(pos)
      @mixin new limber.trait.Velocity(vel)
      @mixin @randomAcceleration
      @mixin @body
      #@mixin @collisionDetection
      #@mixin @flocking
      @mixin @bounded
      @mixin @collisionResponse
      #@mixin @collisionAvoidance
      @mixin new limber.trait.ConstrainSpeed(20, 200)
      
      @on "collision", (engine, mtv, other) ->
        @velocity.reflect(mtv.axis) if other instanceof limber.geometry.Wall

            
    render: (engine) ->
      rect = @body.clone().add(@position)
      size = @body.toVector()
      arrow = @velocity.clone().normalize().scale(10)
      
      
      engine.context.save()
      
      engine.context.fillStyle = "#FF0000" if @collided
      engine.context.closePath()
      engine.context.fillRect(@position.x - 5, @position.y - 5, 10, 10)
      #engine.context.moveTo(@position.x, @position.y)
      #engine.context.arc(@position.x, @position.y, 5, 0, Math.PI * 2, false)
      engine.context.stroke()
      engine.context.fill() if @collided
      engine.context.beginPath()
      engine.context.strokeStyle = "yellow"
      engine.context.moveTo(@position.x, @position.y)
      engine.context.lineTo(@position.x + arrow.x, @position.y + arrow.y)
      engine.context.stroke()
      engine.context.closePath()
      engine.context.restore()
      
      
      
      #engine.context.
      #engine.context.fillStyle = "#FFFFFF"
      #engine.context.translate(@position.x, @position.y)
      #engine.context.scale(1, -1)
      #engine.context.fillText(@id, -size.x/2, size.y/2)
      engine.context.restore()

  
  engine = new limber.engine.Canvas2D("canvas", 800, 600)
    .attach(new limber.component.FPS("fps"))
  
  for i in [0 ... 20]
    engine.attach(new Entity(i, [Math.random() * 800 + 50, Math.random() * 500 + 50], [Math.random() * 200 - 100, Math.random() * 200 - 100]))
  
  engine.animate()

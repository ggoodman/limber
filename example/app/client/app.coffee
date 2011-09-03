# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->

  limber = SS.client.limber.limber
  
  class Entity extends limber.entity.Entity
    randomAcceleration: new limber.trait.RandomAcceleration(10)
    body: new limber.trait.AABBBody(-5, -5, 5, 5)
    collisionDetection: new limber.trait.CollisionDetection
    flocking: new limber.trait.Flocking
    bounded: new limber.trait.Bounded(10, 10, 390, 390)
    collisionResponse: new limber.trait.CollisionResponse
    
    initialize: (@id, pos, vel) ->
      @mixin new limber.trait.Position(pos)
      @mixin new limber.trait.Velocity(vel)
      @mixin @randomAcceleration
      @mixin @body
      #@mixin @collisionDetection
      @mixin @flocking
      @mixin @bounded
      @mixin @collisionResponse

            
    render: (engine) ->
      rect = @body.clone().add(@position)
      size = @body.toVector()
      arrow = @velocity.clone().normalize().scale(5)
      
      engine.context.save()
      engine.context.fillStyle = "#FF0000" if @collided
      engine.context.moveTo(@position.x, @position.y)
      engine.context.arc(@position.x, @position.y, 5, 0, Math.PI * 2, false)
      engine.context.fill()
      engine.context.beginPath()
      engine.context.strokeStyle = "#FFFFFF"
      engine.context.moveTo(@position.x, @position.y)
      engine.context.lineTo(@position.x + arrow.x, @position.y + arrow.y)
      engine.context.closePath()
      engine.context.stroke()
      
      
      #engine.context.
      #engine.context.fillStyle = "#FFFFFF"
      #engine.context.translate(@position.x, @position.y)
      #engine.context.scale(1, -1)
      #engine.context.fillText(@id, -size.x/2, size.y/2)
      engine.context.restore()

  
  engine = new limber.engine.Canvas2D("canvas", 400, 400)
    .attach(new limber.component.FPS("fps"))
  
  for i in [0 ... 100]
    engine.attach(new Entity(i, [Math.random() * 100 + 50, Math.random() * 100 + 50], [Math.random() * 200 - 100, Math.random() * 200 - 100]))
  
  engine.animate()

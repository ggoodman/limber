# This method is called automatically when the websocket connection is established. Do not rename/delete
exports.init = ->

  limber = SS.client.limber.limber
  
  class Entity extends limber.entity.Entity
    randomAcceleration: new limber.trait.RandomAcceleration(5)
    body: new limber.trait.AABBBody(-5, -5, 5, 5)
    flocking: new limber.trait.Flocking
    bounded: new limber.trait.Bounded(0, 0, 800, 600)
    wrapped: new limber.trait.Wrapped(0, 0, 800, 600)
    collisionDetection: new limber.trait.CollisionDetection
    collisionResponse: new limber.trait.CollisionResponse
    collisionAvoidance: new limber.trait.CollisionAvoidance(-0.1, .5, 10, 20)
    
    initialize: (@id, pos, vel) ->
      @mixin new limber.trait.Position(pos)
      @mixin new limber.trait.Velocity(vel)
      @mixin new limber.trait.Acceleration()
      @mixin @randomAcceleration
      @mixin @body
      #@mixin @collisionDetection
      #@mixin @flocking
      #@mixin @collisionResponse
      @mixin @collisionAvoidance
      @mixin new limber.trait.ConstrainSpeed(80, 200)
      @mixin new limber.trait.ConstrainAcceleration(8)
      @mixin @wrapped
      
      @on "collision", (engine, mtv, other) ->
        @velocity.reflect(mtv.axis) if other instanceof limber.geometry.Wall
    
    destroy: ->
      @removeAllListeners()
      #delete this[prop] for prop in this
      @

            
    render: (engine) =>
      rect = @body.clone().add(@position)
      size = @body.toVector()
      arrow = @velocity.clone().add(@acceleration).normalize().scale(10)
      
      
      #engine.context.save()
      
      #engine.context.fillRect(@position.x - 5, @position.y - 5, 10, 10)
      engine.context.moveTo(@position.x, @position.y)
      engine.context.fillStyle = "#999999"
      engine.context.fillRect(rect.bl.x, rect.bl.y, size.x, size.y)
      engine.context.beginPath()
      engine.context.arc(@position.x, @position.y, 3, 0, Math.PI * 2, false)

      engine.context.strokeStyle = "black"
      engine.context.fillStyle = "#CCCCCC"
      engine.context.fillStyle = "#FF0000" if @collided
      #engine.context.stroke()
      engine.context.fill()
      engine.context.closePath()

      engine.context.beginPath()
      engine.context.moveTo(@position.x, @position.y)
      engine.context.lineTo(@position.x + arrow.x, @position.y + arrow.y)

      engine.context.strokeStyle = "#CCCCCC"
      engine.context.strokeWidth = 4
      engine.context.stroke()
      engine.context.closePath()

      engine.context.restore()

  
  engine = new limber.engine.Canvas2D("canvas", 800, 600)
    .attach(new limber.component.FPS("fps"))
  
  entities = []
  
  for i in [0 ... 100]
    entities[i] = new Entity(i, [Math.random() * 800 + 50, Math.random() * 500 + 50], [Math.random() * 200 - 100, Math.random() * 200 - 100])
    engine.attach(entities[i])
    do (i) ->
      entities[i].on "collision", (engine, mtv, other) ->
        unless other instanceof limber.geometry.Wall
          console.log "DEAD", this, entities[i]
          this.destroy()
          engine.detach(this)
          entities[i] = null

  
  engine.animate()

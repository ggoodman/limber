exports.limber = limber =
  version: "0.0.2"
  geometry: {}
  component: {}
  entity: {}
  trait: {}
  engine: {}
  
  #convenience methods
  vector: (x, y) -> new limber.geometry.Vector(x, y)
  box: (x0, y0, x1, y1) -> new limber.geometry.Box(x0, y0, x1, y1)

class limber.EventEmitter
  on: (event, cb) ->
    @listeners ||= {}
    @listeners[event] ||= []
    @listeners[event].push(cb)
    @
  
  echo: (emitter, event, asEvent) ->
    emitter.on event, @trigger(asEvent or event)
  
  emit: (event, args...) ->
    @listeners ||= {}
    cb.apply(this, args) for cb in @listeners[event] when cb if @listeners[event]
    @
  
  removeListener: (event, cb) ->
    @listeners ||= {}
    if listeners = @listeners[event]
      index = listeners.indexOf(cb)
      unless index == -1
        listeners[index] = null
        listeners.splice(index, 1)
    @
  
  removeAllListeners: ->
    @listeners[i] = null for i in @listeners if @listeners
    @
  
  trigger: (event) ->
    self = this
    (args...) -> self.emit(event, args...)

class limber.Timer
  constructor: ->
    @lastTick = @currTick = @+ new Date
  
  tick: ->
    [@currTick, @lastTick] = [+ new Date, @currTick]
    @delta = @currTick - @lastTick

#-----------#
# COMPONENT #
#-----------#


# limber.Component is the basic component used in the engine
class limber.component.Component extends limber.EventEmitter    
  attach: (component) ->
    @children ||= []
    @children.push(component)
    @emit "attach", component
    component.emit("attached", this)
    @
  
  attachTo: (component) ->
    component.attach(this)
    @
    
  detach: (component) ->
    @children ||= []
    unless -1 == (index = @children.indexOf(component))
      @emit "detach", component.emit("detached", this)
      @children[index] = null
      @children.splice(index, 1)
    @

class limber.component.FPS extends limber.component.Component
  constructor: (id) ->
    @el = $(document.getElementById(id))
    @size = 20
    @index = 0
    @sum = 0
    @sample = []
    
    @sample[i] = 0 for i in [0 ... @size]
    
    @on "attached", (component) ->
      component.on "update", @update
      component.on "render", @render
  
  update: (engine) =>
    @sum -= @sample[@index]
    @sum += engine.timer.delta
    
    @sample[@index] = engine.timer.delta
    
    @index += 1
    @index = 0 if @index == @size
  
  render: (engine) =>
    @el.text(Math.floor(1000 / (@sum / @size)) + " FPS")


#--------- #
# GEOMETRY #
#----------#

class limber.geometry.Vector
  constructor: (@x = 0, @y = 0) ->
    if x instanceof limber.geometry.Vector
      @x = x.x
      @y = x.y
    else if Array.isArray(x)
      @x = x[0]
      @y = x[1]
    
  clone: -> new limber.geometry.Vector(@x, @y)
  reset: ->
    @x = 0
    @y = 0
    @
  
  scale: (scalar) ->
    @x *= scalar
    @y *= scalar
    @
  
  shrink: (scalar) ->
    @x /= scalar
    @y /= scalar
    @
  
  product: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    @x *= vector.x
    @y *= vector.y
    @
  
  add: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    @x += vector.x
    @y += vector.y
    @
  
  subtract: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    @x -= vector.x
    @y -= vector.y    
    @
  
  normalize: ->
    if @x == 0 and @y
      @y = if @y > 0 then 1 else -1
    else if @y == 0 and @y
      @x = if @x > 0 then 1 else -1
    else if (magnitude = @magnitude())
    
      @x = @x / magnitude
      @y = @y / magnitude
    @
  
  reflect: (x, y) ->
    normal = new limber.geometry.Vector(x, y).normalize().rotateRight()
    
    @add(normal.scale(-2 * @dot(normal)))   
    @
    
    
  dot: (x, y) ->
    if x instanceof limber.geometry.Vector then return @x * x.x + @y * x.y
    else return @x * x + @y * y

  
  magnitude: -> Math.sqrt(@x * @x + @y * @y)
  magnitudeSq: -> @x * @x + @y * @y
  
  flipX: ->
    @x = - @x
    @
  flipY: ->
    @y = - @y
    @
  flip: ->
    @x = - @x
    @y = - @y
    @
  
  rotateRight: ->
    [@x, @y] = [@y, - @x]
    @

  rotateLeft: ->
    [@x, @y] = [- @y, @x]
    @
    
class limber.geometry.Projection
  constructor: (min, max) ->
    if min instanceof limber.geometry.Projection
      @min = min.min
      @max = min.max
    else
      @min = min
      @max = max
  
  overlap: (x, y) ->
    proj = new limber.geometry.Projection(x, y)
    overlap = 0
    
    unless @max < proj.min or @min > proj.max
      if @min > proj.min and @min < proj.max then overlap = proj.max - @min
      else if @max < proj.max and @max > proj.min then overlap = proj.min - @max
      else
        test = proj.max - proj.min
        overlap = @max - @min
        overlap = test if test < overlap
    
    overlap = Number.MAX_VALUE if overlap is Number.POSITIVE_INFINITY
    overlap = -Number.MAX_VALUE if overlap is Number.NEGATIVE_INFINITY

    #proj = null
    overlap

    
class limber.geometry.MTV
  constructor: (axis, @overlap) ->
    @axis = limber.vector(axis)
  
  flip: ->
    @axis.flip()
    @

class limber.geometry.ConvexHull
  constructor: (vertices...) ->
    @vertices = for vertex in vertices then limber.vector(vertex)
    
  add: (x, y) ->
    vertex.add(x, y) for vertex in @vertices
    @
  subtract: (x, y) ->
    vertex.subtract(x, y) for vertex in @vertices
    @
    
  testCollision: (convex) ->
    return @testPolygonPolygon(convex)
    test = "test"
    test +=
      if this instanceof limber.geometry.Polygon then "Polygon"
      else if this instanceof limber.geometry.Circle then "Circle"
    test +=
      if convex instanceof limber.geometry.Polygon then "Polygon"
      else if convex instanceof limber.geometry.Circle then "Circle"
    
    throw new Error("Collisions method not implemented: #{test}") unless this[test]
    
    method = this[test]
    
    method.call(this, convex)
    
    
  testPolygonPolygon: (convex) ->
    
    minOverlap = Number.POSITIVE_INFINITY
    minAxis = null
    multAxes = false
    
    axes = @getFaceNormals()
    axes.concat(convex.getFaceNormals()) unless this instanceof limber.geometry.AABB and convex instanceof limber.geometry.AABB
    
    for axis in axes
      proj1 = @projectOnto(axis)
      proj2 = convex.projectOnto(axis)
      overlap = proj1.overlap(proj2)
      
      return unless overlap
      if overlap == minOverlap
        minAxis.add(axis)
        multAxes = true
      else if overlap < minOverlap
        multAxes = false
        minOverlap = overlap
        minAxis = axis.clone()
    
    minAxis.normalize() if multAxes
    
    new limber.geometry.MTV(minAxis, minOverlap)
  
  projectOnto: (x, y) ->
    return new limber.geometry.Projection(0, 0) unless @vertices and @vertices.length
    
    axis = limber.vector(x, y)
    min = Number.POSITIVE_INFINITY
    max = Number.NEGATIVE_INFINITY
    
    for vertex in @vertices
      d = axis.dot(vertex)
      min = if d < min then d else min
      max = if d > max then d else max
    
    return new limber.geometry.Projection(min, max)
  
  getFaceNormals: ->
    @normals or @normals = for vertex, i in @vertices
      @vertices[(i + 1) % @vertices.length].clone().subtract(vertex).rotateRight().normalize()
  
  addNormal: (x, y) ->
    @normals ||= []
    @normals.push(limber.vector(x, y))
    @
  addVertex: (x, y) ->
    @vertices ||= []
    @vertices.push(limber.vector(x, y))
    @

  getVertices: -> @vertices or []

class limber.geometry.Polygon extends limber.geometry.ConvexHull

class limber.geometry.AABB extends limber.geometry.Polygon
  constructor: (x0, y0, x1, y1) ->
    if x0 instanceof limber.geometry.AABB
      @bl = x0.bl.clone()
      @tr = x0.tr.clone()
    else if arguments.length == 2
      @bl = new limber.geometry.Vector(x0)
      @tr = new limber.geometry.Vector(y0)
    else if arguments.length == 4
      @bl = new limber.geometry.Vector(x0, y0)
      @tr = new limber.geometry.Vector(x1, y1)
    
    @addVertex(@bl.x, @bl.y)
    @addVertex(@bl.x, @tr.y)
    @addVertex(@tr.x, @tr.y)
    @addVertex(@tr.x, @bl.y)
    
    @normals = [limber.vector(1, 0), limber.vector(0, 1)]
  
  clone: -> new limber.geometry.AABB(@bl, @tr)
  add: (x, y) ->
    @bl.add(x, y)
    @tr.add(x, y)
    super(x, y)
  subtract: (x, y) ->
    @bl.subtract(x, y)
    @tr.subtract(x, y)
    super(x, y)
  
  getFaceNormals: -> @normals
  
  toVector: -> @tr.clone().subtract(@bl)



class limber.geometry.Wall extends limber.geometry.AABB      
  constructor: (x, y, offset, yoff) ->
    #NOTE: ONLY WORKS FOR AABB WALLS FOR NOW
    
    if x
      @addVertex(offset, -Number.MAX_VALUE)
      @addVertex(offset, +Number.MAX_VALUE)
      @addVertex(-x * Number.MAX_VALUE, yoff)
    else
      @addVertex(-Number.MAX_VALUE, offset)
      @addVertex(+Number.MAX_VALUE, offset)
    
      @addVertex(yoff, -y * Number.MAX_VALUE)
    @addNormal(x, y)
    
    normal = null

  # Special case for Walls
  testPolygonCircle: (circle) ->


class limber.geometry.Circle extends limber.geometry.ConvexHull
  

#--------#
# ENGINE #
#--------#

class limber.engine.Canvas2D extends limber.component.Component
  constructor: (id, width, height) ->
    @canvas = document.getElementById(id)
    #WebGL2D.enable(@canvas)

    @canvas.width = width
    @canvas.height = height
    
    @context = @canvas.getContext("2d")
    @timer = new limber.Timer
    
    @context.translate(0, height)
    @context.scale(1, -1)

  animate: ->
    renderer = this
    canvas = @canvas
    
    nextFrame = window.requestAnimationFrame or
      window.webkitRequestAnimationFrame or
      window.mozRequestAnimationFrame or
      window.oRequestAnimationFrame or
      window.msRequestAnimationFrame or
      null 
    
    @timer.tick()
    
    innerFrame = ->
      renderer.timer.tick()
      renderer.emit("update", renderer)
      renderer.context.clearRect(0, 0, canvas.width, canvas.height)
      renderer.emit("render", renderer)
      
    if nextFrame != null
      recursiveFrame = ->
        innerFrame()
        nextFrame(recursiveFrame)
      
      nextFrame(recursiveFrame)
    else
      ONE_FRAME_TIME = 1000.0 / 60.0
      setInterval(innerFrame, ONE_FRAME_TIME)


#--------#
# ENTITY #
#--------#

class limber.entity.Entity extends limber.component.Component
  constructor: (args...) ->
    self = this
    @on "update", @update
    @on "render", @render
    @on "attached", (component) ->
      self.echo component, "update"
      self.echo component, "render"
    @on "detached", ->
      self.removeListener "update", self.update
      self.removeListener "render", self.render
    @initialize(args...)
  
  destroy: ->
    @mixout(trait) for provide, trait of @traits if @traits
    @removeListener "update", @update
    @removeListener "render", @render
    
  mixin: (trait) ->
    provides = if Array.isArray(trait.provides) then trait.provides else [trait.provides]
    requires = if Array.isArray(trait.requires) then trait.requires else [trait.requires]
    
    @traits ||= {}
    @requireTraits(requires)
    
    trait.emit "mixin", this
    
    trait.augment(this)
    
    @traits[name] = trait for name in provides
    @
  
  mixout: (trait) ->
    provides = if Array.isArray(trait.provides) then trait.provides else [trait.provides]
    
    trait.emit "mixout", this

    @traits ||= {}
    
    for provide in provides
      @traits[provide] = null
      delete @traits[provide]

    @
    
  
  requireTraits: (requires...) ->
    requires = requires[0] if Array.isArray(requires[0])
    for name in requires
      throw new Error("Missing required trait: #{name}") unless @traits[name]
    @
    
  attached: -> @
  detached: -> @
  initialize: -> @
  update: -> @
  render: -> @

#-------#
# TRAIT #
#-------#

class limber.trait.Trait extends limber.EventEmitter
  provides: []
  requires: []

  constructor: (args...) ->
    self = this
    @initialize(args...)
  
  destroy: ->
    @removeAllListeners()
    
  initialize: -> @
  augment: -> @
  
class limber.trait.Position extends limber.trait.Trait
  provides: "position"
  initialize: (x, y) -> @position = limber.vector(x, y)
    
  augment: (entity) -> entity.position = @position

class limber.trait.Velocity extends limber.trait.Trait
  provides: "velocity"
  requires: "position"
  initialize: (x, y) -> @velocity = limber.vector(x, y)
  augment: (entity) ->
    entity.velocity = @velocity
    entity.on "update", (engine) ->
      @position.add @velocity.clone().scale(engine.timer.delta / 1000)


class limber.trait.Acceleration extends limber.trait.Trait
  provides: "acceleration"
  requires: "velocity"
  initialize: (x, y) -> @acceleration = limber.vector(x, y)
  augment: (entity) ->
    entity.acceleration = @acceleration
    entity.on "update", (engine) ->
      @velocity.add @acceleration
      @acceleration.reset()

class limber.trait.AABBBody extends limber.trait.Trait
  provides: "body"
  initialize: (x0, y0, x1, y1) -> @aabb = new limber.geometry.AABB(x0, y0, x1, y1)
  augment: (entity) -> entity.body = @aabb

class limber.trait.Bounded extends limber.trait.Trait
  requires: ["position", "body"]
  
  constructor: (x0, y0, x1, y1) ->
    boundaries = [
      new limber.geometry.Wall(1, 0, x0, y1)
      new limber.geometry.Wall(0, 1, y0, x1)
      new limber.geometry.Wall(-1, 0, x1, y0)
      new limber.geometry.Wall(0, -1, y1, x0)
    ]
    
    self = this
    @on "augment", (entity) ->
      entity.on "update", (engine) ->
        entity = @
        bounds = entity.body.clone().add(entity.position)
        
        for wall in boundaries
          if mtv = bounds.testCollision(wall)
            @emit "collision", engine, mtv, wall

class limber.trait.Wrapped extends limber.trait.Trait
  requires: ["position", "body"]
  initialize: (@x0, @y0, @x1, @y1) ->  
  augment: (entity) ->
    self = this
    entity.on "update", (engine) ->
      if @position.x < self.x0 then @position.x = self.x1 - self.x0 - entity.position.x
      else if @position.x > self.x1 then @position.x = self.x0 - self.x1 + entity.position.x
      if @position.y < self.y0 then @position.y = self.y1 - self.y0 - entity.position.y
      else if @position.y > self.y1 then @position.y = self.y0 - self.y1 + entity.position.x
      @


class limber.trait.CollisionDetection extends limber.trait.Trait
  requires: ["position", "body"]

  initialize: ->
    @seenInFrame = []
    
  augment: (entity) ->
    self = this
    
    entity.on "render", -> @seenInFrame = []
    entity.on "update", (engine) ->
      myBody = entity.body.clone().add(entity.position)
      for other in @seenInFrame
        otherBody = other.body.clone().add(other.position)
        
        if mtv = myBody.testCollision(otherBody)
          entity.emit "collision", engine, mtv, other
          other.emit "collision", engine, mtv.flip(), entity
      @seenInFrame.push(entity)

class limber.trait.CollisionAvoidance extends limber.trait.Trait
  requires: ["position", "velocity", "acceleration", "body"]
  provides: "avoidance"
  
  initialize: (@short, @far, @closeWidth, @farWidth) ->
    @flock = []
    @seenInFrame = []
    
  augment: (entity) ->
    self = this
    #self.flock.push(entity)
    entity.on "update", -> self.avoid(entity)
    entity.on "render", (engine) ->
      self.seenInFrame = []
      if @avoidance and true
        engine.context.save()
        engine.context.beginPath()
        grad = engine.context.createLinearGradient(@avoidance.vertices[0].x, @avoidance.vertices[0].y, @avoidance.vertices[1].x, @avoidance.vertices[1].y)
        grad.addColorStop 0, if @avoid then "rgba(255, 0, 0, 0.2)" else "rgba(255, 255, 0, 0.2)"
        grad.addColorStop 0.8, "rgba(0, 0, 0, 0.2)"
        grad.addColorStop 1, "rgba(0, 0, 0, 0)"
        engine.context.moveTo(@avoidance.vertices[0].x, @avoidance.vertices[0].y)
        engine.context.lineTo(@avoidance.vertices[1].x, @avoidance.vertices[1].y)
        engine.context.lineTo(@avoidance.vertices[2].x, @avoidance.vertices[2].y)
        engine.context.lineTo(@avoidance.vertices[3].x, @avoidance.vertices[3].y)
        engine.context.closePath()
        engine.context.strokeStyle = "gray"
        engine.context.fillStyle = grad#if @avoid then "rgba(255, 0, 0, 0.2)" else "rgba(255, 255, 0, 0.2)"
        #engine.context.stroke()
        engine.context.fill()
        engine.context.restore()
  
  avoid: (entity) ->
    accel = new limber.geometry.Vector
    
    vel = entity.velocity.clone()
    dir = vel.clone().normalize()
    pos = entity.position.clone().add(vel.clone().scale(@short))
    normal = dir.clone().rotateRight()
    ahead = @far - @short
    
    w = (@farWidth - @closeWidth) / 2
    
    entity.avoidance = new limber.geometry.Polygon
    entity.avoidance.addVertex(pos.add(normal.clone().scale(@closeWidth / 2))) #side, right
    entity.avoidance.addVertex(pos.add(vel.clone().scale(ahead).add(normal.clone().scale(w)))) #front, right
    entity.avoidance.addVertex(pos.add(normal.clone().scale(- @farWidth))) #front, left
    entity.avoidance.addVertex(pos.add(vel.clone().scale(- ahead).add(normal.clone().scale(w)))) #side, left
    
    entity.avoid = false
    
    for boid in @seenInFrame when boid != entity and boid.avoidance instanceof limber.geometry.Polygon
      if mtv = boid.avoidance.testCollision(entity.avoidance)
        entity.avoid = true
        entity.acceleration.subtract(mtv.axis.scale(mtv.overlap))
        
        boid.avoid = true
        boid.acceleration.add(mtv.axis) #Already scaled above
      
    @seenInFrame.push(entity)

  
class limber.trait.Flocking extends limber.trait.Trait
  requires: ["position", "velocity"]
  
  constructor: ->
    self = this
    @flock = []
    
    @on "augment", (entity) ->
      self.flock.push(entity)
      entity.on "update", -> self.steer(entity)

  steer: (entity) ->
    approach = new limber.geometry.Vector(0, 0)
    avoid = new limber.geometry.Vector(0, 0)
    match = new limber.geometry.Vector(0, 0)
    accel = new limber.geometry.Vector(0, 0)
    
    approach.n = avoid.n = match.n = 0
    
    for boid in @flock when boid != entity
      dist = boid.position.clone().subtract(entity.position)
      dist2 = dist.magnitudeSq()
      
      if dist2 < 10000
        approach.add(dist.clone().scale(0.0001))
        approach.n++
      if dist2 < 800
        avoid.subtract(boid.position.clone().subtract(entity.position).shrink(dist2 / 200))
        avoid.n++
      if dist2 < 1000
        match.add(boid.velocity.clone().subtract(entity.velocity).scale(0.01))
        match.n++

    approach.shrink(approach.n) if approach.n
    avoid.shrink(avoid.n) if avoid.n
    match.shrink(match.n) if match.n


    accel
      .add(approach)
      .add(avoid)
      .add(match)
      .normalize()
      .scale(8)
      
    #unless not @once and accel.magnitude()
    #  @once = true
    #  console.log "WTF", accel

    entity.velocity.add(accel)

    


class limber.trait.CollisionResponse extends limber.trait.Trait
  requires: "velocity"
  constructor: ->
    @on "augment", (entity) ->
      entity.on "render", -> @collided = false
      entity.on "collision", (engine, mtv, other) ->
        @collided = true
        @position.add(mtv.axis.clone().scale(mtv.overlap / 2))

class limber.trait.RandomAcceleration extends limber.trait.Trait
  requires: "acceleration"
  
  constructor: (@speed = 20) ->
  augment: (entity) ->
    speed = @speed
    twiceSpeed = speed * 2
    entity.on "update", (engine) ->
      @acceleration.add(Math.random() * twiceSpeed - speed, Math.random() * twiceSpeed - speed)

class limber.trait.ConstrainSpeed extends limber.trait.Trait
  requires: "velocity"
  
  constructor: (@min = 20, @max = 200) ->
    
  augment: (entity) ->
    min = @min
    max = @max
    minSq = min * min
    maxSq = max * max
    entity.on "update", (engine) ->
      v2 = @velocity.magnitudeSq()
      if v2 > maxSq then @velocity.scale(Math.sqrt(v2) / maxSq) 
      else if v2 < minSq then @velocity.scale(min / Math.sqrt(v2))

class limber.trait.ConstrainAcceleration extends limber.trait.Trait
  requires: "velocity"
  
  constructor: (@max = 20) ->
    
  augment: (entity) ->
    max = @max
    maxSq = max * max
    entity.on "update", (engine) ->
      v2 = @acceleration.magnitudeSq()
      if v2 > maxSq then @acceleration.normalize().scale(max)

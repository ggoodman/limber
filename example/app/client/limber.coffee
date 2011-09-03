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
    cb.apply(this, args) for cb in @listeners[event] if @listeners[event]
    @
  
  removeListener: (event, cb) ->
    @listeners ||= {}
    if listeners = @listeners[event]
      index = listeners.indexOf(cb)
      listeners.splice(index, 1) unless index == -1
  
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
    @emit "attach", component.emit("attached", this)
    @
  
  attachTo: (component) ->
    component.attach(this)
    @
    
  detach: (component) ->
    @children ||= []
    @children.splice(index, 1) unless -1 == (index = @children.indexOf(component))
    @emit "detach", component.emit("detached", this)
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
  constructor: (x = null, y = null) ->
    [@x, @y] = 
      if x instanceof limber.geometry.Vector then [x.x, x.y]
      else if Array.isArray(x) then x
      else if x !=  null and y != null then [x, y]
      else [0, 0]
      
    x = null
    y = null
    
  clone: -> new limber.geometry.Vector(this)
  
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
    
    vector = null
    
    @
  
  add: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    @x += vector.x
    @y += vector.y
    
    vector = null
    
    @
  
  subtract: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    @x -= vector.x
    @y -= vector.y
    
    vector = null
    
    @
  
  normalize: ->
    if @x == 0
      @y = 1
    else if @y == 0
      @x = 1
    else
      magnitude = @magnitude()
      
      @x /= magnitude
      @y /= magnitude
    @
  
  reflect: (x, y) ->
    normal = new limber.geometry.Vector(x, y).normalize().flipY()
    
    @add(normal.scale(-2 * @dot(normal)))
    
    normal = null
    
    @
    
    
  dot: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    dot = @x * vector.x + @y * vector.y
    
    vector = null
    
    dot
  
  magnitude: -> Math.sqrt(@x * @x + @y * @y)
  magnitudeSq: -> @x * @x + @y * @y
  
  flipX: ->
    @x = - @x
    @
  flipY: ->
    @y = - @y
    @
  flip: -> @flipX().flipY()
  
  rotateRight: ->
    [@x, @y] = [@y, -@x]
    @

  rotateLeft: ->
    [@x, @y] = [-@y, @x]
    @

class limber.geometry.Projection
  constructor: (x = null, y = null) ->
    [@min, @max] = 
      if x instanceof limber.geometry.Projection then [x.min, x.max]
      else if Array.isArray(x) then x
      else [x, y]
      #else [0, 0]
    x = null
    y = null
  
  overlap: (x, y) ->
    proj = new limber.geometry.Projection(x, y)
    overlap = 0
    
    unless @max < proj.min or @min > proj.max
      if @min > proj.min and @min < proj.max then overlap = proj.max - @min
      else if @max < proj.max and @max > proj.min then overlap = proj.min - @max
      else overlap = @max - @min

    proj = null
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
    minOverlap = Number.POSITIVE_INFINITY
    minAxis = null
    multAxes = false
    
    for axis in @getFaceNormals().concat(convex.getFaceNormals())
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
      min = Math.min(min, d)
      max = Math.max(max, d)
    
    new limber.geometry.Projection(min, max)
  
  getFaceNormals: ->
    @normals or @normals = for vertex, i in @vertices
      @vertices[(i + 1) % @vertices.length].clone().subtract(vertex).rotateRight().normalize()
  
  addVertex: (x, y) ->
    @vertices ||= []
    @vertices.push(limber.vector(x, y))
    @

  getVertices: -> @vertices or []

class limber.geometry.Wall extends limber.geometry.ConvexHull
  constructor: (x0, y0, x1, y1) ->
    if arguments.length == 2
      @vertices = [new limber.geometry.Vector(x0)]
      @normals = [new limber.geometry.Vector(y0)]
    else if arguments.length == 4
      @vertices = [new limber.geometry.Vector(x0, y0)]
      @normals = [new limber.geometry.Vector(x1, y1)]
      


class limber.geometry.AABB extends limber.geometry.ConvexHull
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

class limber.geometry.Box extends limber.geometry.ConvexHull
  constructor: (x0, y0, x1, y1) ->
    if x0 instanceof limber.geometry.Box
      @tl = x0.tl.clone()
      @br = x0.br.clone()
    else if arguments.length == 2
      @tl = new limber.geometry.Vector(x0)
      @br = new limber.geometry.Vector(y0)
    else if arguments.length == 4
      @tl = new limber.geometry.Vector(x0, y0)
      @br = new limber.geometry.Vector(x1, y1)
  
  clone: -> new limber.geometry.Box(this)
  add: (vector) ->
    @tl.add(vector)
    @br.add(vector)
    @
    
  toVector: -> new limber.geometry.Vector(@br.x - @tl.x, @br.y - @tl.y)
  
  intersect: (box) ->
    return null if box.tl.x >= @br.x or box.br.x <= @tl.x or box.tl.y >= @br.y or box.br.y <= @tl.y
    return new limber.geometry.Box Math.max(box.tl.x, @tl.x), Math.max(box.tl.y, @tl.y), Math.min(box.br.x, @br.x), Math.min(box.br.y, @br.y)

#--------#
# ENGINE #
#--------#

class limber.engine.Canvas2D extends limber.component.Component
  constructor: (id, width, height) ->
    @canvas = document.getElementById(id)
    
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
    @initialize(args...)
    
  mixin: (trait, name) ->
    provides = if Array.isArray(trait.provides) then trait.provides else [trait.provides]
    requires = if Array.isArray(trait.requires) then trait.requires else [trait.requires]
    
    @traits ||= {}
    @requireTraits(requires)
    trait.emit("augment", this)
    @traits[name] = trait for name in provides
    @
  
  requireTraits: (requires...) ->
    requires = requires[0] if Array.isArray(requires[0])
    for name in requires
      throw new Error("Missing required trait: #{name}") unless @traits[name]
    @
    
  
  initialize: -> @
  update: -> @
  render: -> @

#-------#
# TRAIT #
#-------#

class limber.trait.Trait extends limber.EventEmitter
  provides: []
  requires: []
  augment: (entity) -> @
  
class limber.trait.Position extends limber.trait.Trait
  provides: "position"
  constructor: (x, y) ->
    @on "augment", (entity) -> entity.position = limber.vector(x, y)

class limber.trait.Velocity extends limber.trait.Trait
  provides: "velocity"
  requires: "position"
  constructor: (x, y) ->
    @on "augment", (entity) ->
      entity.velocity = limber.vector(x, y)
      entity.on "update", (engine) ->
        entity.position.add entity.velocity.clone().scale(engine.timer.delta / 1000)

class limber.trait.AABBBody extends limber.trait.Trait
  provides: "body"
  
  constructor: (x0, y0, x1, y1) ->
    aabb = new limber.geometry.AABB(x0, y0, x1, y1)
  
    @on "augment", (entity) -> entity.body = aabb

class limber.trait.Bounded extends limber.trait.Trait
  requires: ["position", "body"]
  
  constructor: (x0, y0, x1, y1) ->
    #TODO: Better solution for minimum and maximum
    min = -1000
    max = 1000
    
    boundaries = [
      new limber.geometry.AABB(min, min, x0, max)
      new limber.geometry.AABB(min, min, max, y0)
      new limber.geometry.AABB(x1, min, max, max)
      new limber.geometry.AABB(min, y1, max, max)
      #new limber.geometry.Wall(x0, y0, 1, 0)
      #new limber.geometry.Wall(x0, y0, 0, 1)
      #new limber.geometry.Wall(x1, y1, -1, 0)
      #new limber.geometry.Wall(x1, y1, 0, -1)
    ]
    
    self = this
    @on "augment", (entity) ->
      entity.on "render", (engine) ->
        for wall in boundaries
          rect = wall
          size = wall.toVector()
          engine.context.save()
          engine.context.fillStyle = "#00FF00"
          engine.context.fillRect(rect.bl.x, rect.bl.y, size.x, size.y)
          engine.context.restore()
          
          engine.context.fillRect(boundaries[0].bl.x, boundaries[0].bl.y, 
      entity.on "update", (engine) ->
        entity = @
        bounds = entity.body.clone().add(entity.position)
        
        for wall in boundaries
          if mtv = bounds.testCollision(wall)
            entity.emit "collision", engine, mtv, wall

class limber.trait.CollisionDetection extends limber.trait.Trait
  requires: ["position", "body"]

  constructor: ->
    bodies = []
    self = this
    seenInFrame = []
    
    @on "augment", (entity) -> 
      entity.on "render", -> seenInFrame = []
      entity.on "update", (engine) ->
        myBody = entity.body.clone().add(entity.position)
        for other in seenInFrame
          otherBody = other.body.clone().add(other.position)
          
          if mtv = myBody.testCollision(otherBody)
            entity.emit "collision", engine, mtv, other
            other.emit "collision", engine, mtv.flip(), entity
        seenInFrame.push(entity)

class limber.trait.Flocking extends limber.trait.Trait
  requires: ["position", "velocity"]
  
  constructor: ->
    self = this
    @flock = []
    
    @on "augment", (entity) ->
      self.flock.push(entity)
      entity.on "update", -> self.steer(entity)

  steer: (entity) ->
    accel = new limber.geometry.Vector
    
    for boid in @flock when boid != entity
      dist = boid.position.clone().subtract(entity.position)
      dist2 = dist.magnitudeSq()
      
      if dist2 < 2000 then accel.add(dist.clone().scale(0.0075 / @flock.length))
      if dist2 < 800 then accel.subtract(boid.position.clone().subtract(entity.position).scale(Math.pow((800 - dist2) / 400, 4)))
      if dist2 < 2000 then accel.add(boid.velocity.clone().subtract(entity.velocity).scale(8 / @flock.length))

    if (a2 = accel.magnitudeSq()) > 400 then accel.scale(200 / a2)
    
    entity.velocity.add(accel)
    
    vel = entity.velocity.magnitude()
    if vel < 100 then entity.velocity.scale(1.2)
    else if vel > 400 then entity.velocity.scale(0.5)

class limber.trait.CollisionResponse extends limber.trait.Trait
  requires: "velocity"
  constructor: ->
    @on "augment", (entity) ->
      entity.on "render", -> @collided = false
      entity.on "collision", (engine, mtv, other) ->
        @collided = true
        entity.velocity.reflect(mtv.axis)
        entity.position.add(mtv.axis.scale(mtv.overlap))

class limber.trait.RandomAcceleration extends limber.trait.Trait
  requires: "velocity"
  
  constructor: (speed = 20) ->
    twiceSpeed = speed * 2
    @on "augment", (entity) ->
      entity.on "update", (engine) ->
        entity.velocity.add(Math.random() * twiceSpeed - speed, Math.random() * twiceSpeed - speed)
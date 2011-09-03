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
      else overlap = Math.min(@max - @min, proj.max - proj.min)
    
    overlap = Number.MAX_VALUE if overlap is Number.POSITIVE_INFINITY
    overlap = -Number.MAX_VALUE if overlap is Number.NEGATIVE_INFINITY

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
###
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
###

class limber.geometry.Circle extends limber.geometry.ConvexHull
  

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
    boundaries = [
      new limber.geometry.Wall(1, 0, x0, y1)
      new limber.geometry.Wall(0, 1, y0, x1)
      new limber.geometry.Wall(-1, 0, x1, y0)
      new limber.geometry.Wall(0, -1, y1, x0)
    ]
    
    self = this
    @on "augment", (entity) ->
      entity.on "render", (engine) ->
        for wall in boundaries
          engine.context.save()
          engine.context.moveTo(wall.vertices[0].x, wall.vertices[0].y)
          engine.context.lineTo(wall.vertices[1].x, wall.vertices[1].y)
          engine.context.stroke()
          engine.context.restore()

      entity.on "update", (engine) ->
        entity = @
        bounds = entity.body.clone().add(entity.position)
        
        for wall in boundaries
          if mtv = bounds.testCollision(wall)
            @emit "collision", engine, mtv, wall

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

class limber.trait.CollisionAvoidance extends limber.trait.Trait
  requires: ["position", "velocity", "body"]
  
  constructor: ->
    self = this
    @flock = []
    
    @on "augment", (entity) ->
      self.flock.push(entity)
      entity.on "update", -> self.avoid(entity)
      ###
      entity.on "render", (engine) ->
        if @view
          engine.context.save()
          engine.context.beginPath()
          engine.context.moveTo(@view.vertices[0].x, @view.vertices[0].y)
          engine.context.lineTo(@view.vertices[1].x, @view.vertices[1].y)
          engine.context.lineTo(@view.vertices[2].x, @view.vertices[2].y)
          engine.context.lineTo(@view.vertices[3].x, @view.vertices[3].y)
          engine.context.stroke()
          engine.context.closePath()
          engine.context.restore()
      ###
  
  avoid: (entity) ->
    accel = new limber.geometry.Vector
    
    vel = 30#entity.velocity.clone().magnitude()
    dir = entity.velocity.clone().normalize()
    pos = entity.position.clone()
    normal = dir.clone().rotateRight()
    
    entity.view = new limber.geometry.Polygon
    entity.view.addVertex(pos.add(normal.clone().scale(10))) #side, right
    entity.view.addVertex(pos.add(dir.clone().scale(vel).add(normal.clone().scale(1)))) #front, right
    entity.view.addVertex(pos.add(normal.clone().scale(- 20))) #front, left
    entity.view.addVertex(pos.add(dir.clone().scale(- vel).add(normal.clone().scale(1)))) #side, left
    
    for boid in @flock when boid != entity
      if mtv = boid.body.clone().add(boid.position).testCollision(entity.view)
        entity.velocity.subtract(mtv.axis.scale(mtv.overlap))

  
class limber.trait.Flocking extends limber.trait.Trait
  requires: ["position", "velocity"]
  
  constructor: ->
    self = this
    @flock = []
    
    @on "augment", (entity) ->
      self.flock.push(entity)
      entity.on "update", -> self.steer(entity)

  steer: (entity) ->
    approach = new limber.geometry.Vector
    avoid = new limber.geometry.Vector
    match = new limber.geometry.Vector
    accel = new limber.geometry.Vector
    
    avoid.n = match.n = accel.n = 0
    
    for boid in @flock when boid != entity
      dist = boid.position.clone().subtract(entity.position)
      dist2 = dist.magnitudeSq()
      
      if dist2 < 2000
        approach.add(dist.clone().scale(0.001))
        approach.n++
      if dist2 < 800
        avoid.subtract(boid.position.clone().subtract(entity.position).shrink(dist2 / 200))
        avoid.n++
      if dist2 < 1000
        match.add(boid.velocity.clone().subtract(entity.velocity).scale(0.1))
        match.n++

    approach.shrink(approach.n) if approach.n
    avoid.shrink(avoid.n) if avoid.n
    match.shrink(match.n) if match.n


    accel
      .add approach
      .add avoid
      #.add match
      .normalize()
      .scale(1)

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
  requires: "velocity"
  
  constructor: (speed = 20) ->
    twiceSpeed = speed * 2
    @on "augment", (entity) ->
      entity.on "update", (engine) ->
        entity.velocity.add(Math.random() * twiceSpeed - speed, Math.random() * twiceSpeed - speed)

class limber.trait.ConstrainSpeed extends limber.trait.Trait
  requires: "velocity"
  
  constructor: (min = 20, max = 200) ->
    minSq = min * min
    maxSq = max * max
    
    @on "augment", (entity) ->
      entity.on "update", (engine) ->
        entity.velocity.scale(Math.sqrt(v) / maxSq) if (v = entity.velocity.magnitudeSq()) > maxSq
        entity.velocity.scale(min / Math.sqrt(v)) if v < minSq 
exports.limber = limber =
  version: "0.0.2"
  geometry: {}
  component: {}
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
    
  detach: (component) ->
    @children ||= []
    @children.splice(index, 1) unless -1 == (index = @children.indexOf(component))
    @emit "detach", component.emit("detached", this)
    @
  
  mixin: (name, trait) ->
    @traits ||= {}
    @traits[name] = trait
    
    trait.augment(this)

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
    
  clone: -> new limber.geometry.Vector(this)
  
  scale: (scalar) ->
    @x *= scalar
    @y *= scalar
    @
  
  shrink: (scalar) ->
    @x /= scalar
    @y /= scalar
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
    magnitude = @magnitude()
    
    @x /= magnitude
    @y /= magnitude
    @
  
  reflect: (x, y) ->
    normal = new limber.geometry.Vector(x, y).normalize().flipY()
    
    @add(normal.scale(-2 * @dot(normal)))
    
    
  dot: (x, y) ->
    vector = new limber.geometry.Vector(x, y)
    
    @x * vector.x + @y * vector.y
  
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

class limber.geometry.Projection
  constructor: (x = null, y = null) ->
    [@min, @max] = 
      if x instanceof limber.geometry.Projection then [x.min, x.max]
      else if Array.isArray(x) then x
      else if x !=  null and y != null then [x, y]
      else [0, 0]
  
  overlap: (x, y) ->
    proj = new limber.geometry.Projection(x, y)
    
    Math.min(@max, proj.max) - Math.max(@min, proj.min)
    
  
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
      overlap = @projectOnto(axis).overlap(convex.projectOnto(axis))
      return unless overlap
      if overlap == minOverlap
        minAxis.add(axis)
        multAxes = true
      else if overlap < minOverlap
        multAxes = false
        minOverlap = overlap
        minAxis = axis.clone()
    
    minAxis.normalize() if multAxes
    
    [minAxis, minOverlap]
  
  projectOnto: (x, y) ->
    throw new Error("Missing vertices") unless @vertices and @vertices.length
    
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
      

class limber.geometry.AABB extends limber.geometry.ConvexHull
  constructor: (x, y, @halfWidth, @halfHeight) ->
    @center = limber.vector(x, y)
    
    @addVertex(x - @halfWidth, y - @halfHeight)
    @addVertex(x - @halfWidth, y + @halfHeight)
    @addVertex(x + @halfWidth, y - @halfHeight)
    @addVertex(x + @halfWidth, y + @halfHeight)
  
  clone: -> new limber.geometry.AABB(@center.x, @center.y, @halfWidth, @halfHeight)
  add: (x, y) ->
    @center.add(limber.vector(x, y))
    super(x, y)
  subtract: (x, y) ->
    @center.subtract(limber.vector(x, y))
    super(x, y)
  
  getFaceNormals: ->
    [limber.vector(1, 0), limber.vector(0, 1)]


class limber.geometry.Box
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



#-------#
# TRAIT #
#-------#

class limber.trait.Trait
  augment: (component) -> @
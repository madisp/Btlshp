root = exports ? this

# important constants
canvas_h = 320
canvas_w = 640

game_h = 320
game_w = 640

# align game to the top-left corner
game_x = 0
game_y = 0

# tile size constants
tile_h = 32
tile_w = 64

# tile halfsize constants
tile_hh = 16
tile_hw = 32

# ship sprite sizes
ship_w = 160
ship_h = 96

# Our point zero
p0 = {
  x: game_x
  y: game_y + game_h / 2
}

# translates a (0..10, 0..10) range point
# to canvas coordinates
p = (x, y) ->
  {
    x: p0.x + tile_hw * (x + y)
    y: p0.y + tile_hh * (y - x)
  }

# translates a canvas coordinate to the closest range point
rp = (x, y) ->
  ny = (x - p0.x)/tile_w + (y - p0.y)/tile_h
  nx = (x-p0.x)/tile_hw - ny
  {
    x: Math.floor nx
    y: Math.floor ny
  }

# convenience methods

line = (ctx, p) ->
  ctx.lineTo(p.x, p.y)

move = (ctx, p) ->
  ctx.moveTo(p.x, p.y)

clear = (layer) ->
  del = []
  for child in layer.children
    del.push child

  for child in del
    layer.remove child


# init the canvas

init_canvas = () ->
  console.log 'creating canvas'
  stage = new Kinetic.Stage 'game-canvas', canvas_w, canvas_h
  stage

images = {}
sources = [
  # sea tiles
#  'ocean_1', 'ocean_2',
  # not using tiles anymore, prerendering background instead
  'background',
  # ship tiles
  'carrier_x', 'carrier_y',
  'battleship_x', 'battleship_y',
  'destroyer_x', 'destroyer_y',
  'sub_x', 'sub_y',
  # fx
  'bomb', 'nuke', 'flag'
]

draw_ship = (layer, src, p) ->
  p.y -= 5*tile_hh
  ori = src.charAt( src.length - 1 )
  if ori == 'y'
    p.x -= 3*tile_hw

  ship = new Kinetic.Image(
    x: p.x
    y: p.y
    image: images[src]
  )
  layer.add ship

draw_nuke = (layer, p) ->
  img = new Kinetic.Image(
    x: p.x + (tile_hw - 16)
    y: p.y - 24
    image: images['nuke']
    alpha: 0.5
  )
  layer.add img

draw_flag = (layer, p) ->
  img = new Kinetic.Image(
    x: p.x
    y: p.y - 2 - tile_hh
    image: images['flag']
  )
  layer.add img

draw_ships = (stage) ->
  ships = new Kinetic.Layer
  draw_ship(ships, 'carrier_y', p(0,9))
  draw_ship(ships, 'sub_x', p(0,0))
  draw_ship(ships, 'sub_y', p(4,7))
  draw_ship(ships, 'sub_x', p(3,1))
  draw_ship(ships, 'sub_y', p(7,3))
  draw_ship(ships, 'battleship_x', p(3,5))
  draw_ship(ships, 'battleship_y', p(7,8))
  draw_ship(ships, 'destroyer_x', p(2,3))
  draw_ship(ships, 'destroyer_y', p(5, 2))
  draw_ship(ships, 'destroyer_x', p(4, 9))
  stage.add ships

draw_smoke = (stage) ->
  smoke = new Kinetic.Layer
  stage.add smoke
  
draw_bomb = (stage, x, y) ->
  bomb = new Kinetic.Layer
  bomb_bmp = new Kinetic.Image(
    x: x-6
    y: y-6
    image: images['bomb']
  )
  bomb.add bomb_bmp
  stage.add bomb

ship_len = (type) ->
  switch type
    when 'carrier' then 4
    when 'battleship' then 3
    when 'destroyer' then 2
    when 'sub' then 1

valid_matrix = (layer) ->
  children = layer.children

  ret = []

  for x in [0...10]
    ret[x] = []
    for y in [0...10]
      ret[x][y] = true

  # calculates a rect with two points (p1,p2)
  mask = (anchor, length, orientation) ->
    switch orientation
      when 'x' then [{x:anchor.x-1,y:anchor.y-1},{x:anchor.x+length,y:anchor.y+1}]
      when 'y' then [{x:anchor.x-1,y:anchor.y-length},{x:anchor.x+1,y:anchor.y+1}]

  clamp = (mask_r) ->
    [
      {x: Math.max(mask_r[0].x, 0), y: Math.max(mask_r[0].y, 0)},
      {x: Math.min(mask_r[1].x, 9), y: Math.min(mask_r[1].y, 9)}
    ]

  for i in [0...children.length]
    if children[i] instanceof Kinetic.Image
      ship = children[i]
      if ship.point?
        anchor = ship.point
        mask_r = mask(anchor, ship_len(ship.type), ship.orientation)
        mask_rect = clamp(mask_r)
        for x in [mask_rect[0].x .. mask_rect[1].x]
          for y in [mask_rect[0].y .. mask_rect[1].y]
            ret[x][y] = false
  ret

class root.BtlBoard
  # canvas stage
  stage: undefined
  # drawing layers
  terrain: undefined
  prep_overlay: undefined
  ships: undefined
  smoke: undefined
  bomb: undefined
  # raw board data
  local:
    ships: []
    smoke: []
    visible: false
  remote:
    ships: []
    smoke: []
    visible: false
  # mouse helpers
  aim:
    x: -1
    y: -1

  preload_images: (cb) =>
    n = 0
    for src in sources
      console.log 'preloading ' + src + '.png'
      images[src] = new Image
      images[src].onload = () ->
        n += 1
        if (n >= sources.length)
          cb()
      images[src].src = '/assets/' + src + '.png'

  add_prep_overlay: (types) =>
    layer = @prep_overlay = new Kinetic.Layer

    overlay = new Kinetic.Shape(
      drawFunc = () ->
        valid = valid_matrix(layer)
        ctx = this.getContext()
        ctx.fillStyle = 'green'
        ctx.strokeStyle = 'white'
        ctx.globalAlpha = '0.7'
        for x in [0..9]
          for y in [0..9]
            if valid[x][y]
              ctx.beginPath()
              move(ctx, p(x, y))
              line(ctx, p(x+1, y))
              line(ctx, p(x+1, y+1))
              line(ctx, p(x, y+1))
              ctx.closePath()
              ctx.fill()
              ctx.stroke()
        ctx.globalAlpha = '1.0'
    )
    @prep_overlay.add overlay
    this.place_ship types, 'x'
    @stage.add @prep_overlay

  place_ship: (type_arr, orientation) =>
    console.log('placing ships')
    console.log(type_arr)
    console.log(orientation)

    layer = @prep_overlay
    type = type_arr.shift()
    fn = this.place_ship

    again = (ship) ->
      layer.remove ship
      type_arr.unshift ship.type
      fn(type_arr, orientation)
      layer.draw()

    if type?
      ship = new Kinetic.Image(
        x: 0
        y: 0
        image: images[type + '_' + orientation]
      )
      ship.type = type
      ship.orientation = orientation
      ship.draggable(true)
      ship.on('dblclick dbltap', () ->
        unless ship.point?
          if orientation == 'x'
            orientation = 'y'
          else
            orientation = 'x'
          again(ship)
      )

      was_placed = false

      ship.on('dragstart', () -> 
        console.log('dragstart')
        console.log("x: #{ship.x} y: #{ship.y}")
        ship.alpha = '0.7'
        was_placed = ship.point?
        ship.point = undefined # "raise" the ship
        root.game.prepDone(false)
      )
      ship.on('dragend', () ->
        ship.alpha = '1.0'
        console.log('dragend')
        if (orientation == 'x')
          np = rp(ship.x + tile_hw, ship.y + ship_h - tile_hh)
        else
          np = rp(ship.x + ship_w - tile_hw, ship.y + ship_h - tile_hh)
        # is the new point valid?

        validate = (ship, np) ->
          mat = valid_matrix(layer)
          shipl = ship_len(ship.type)
          if orientation == 'x'
            xmul = 1
            ymul = 0
          else
            xmul = 0
            ymul = -1
          for i in [0...shipl]
            nx = np.x + (xmul*i)
            ny = np.y + (ymul*i)
            return false unless (nx in [0..9] and ny in [0..9] and mat[nx][ny])
          return true

        if was_placed
          # remove the ship currently in limbo, if any
          limboship = null
          for s in layer.children
            if s instanceof Kinetic.Image and not s.point?
              limboship = s
          if limboship?
            type_arr.unshift(limboship.type)
            layer.remove(limboship)

        if (validate(ship, np))
          ship.point = np
          roundpoint = p(ship.point.x, ship.point.y)
          if (orientation == 'x')
            ship.x = roundpoint.x
            ship.y = roundpoint.y - ship_h + tile_hh
          else
            ship.x = roundpoint.x - ship_w + tile_w
            ship.y = roundpoint.y - ship_h + tile_hh
          # next ship
          fn(type_arr, orientation)
          layer.draw()
        else
          again(ship)
      )
      @prep_overlay.add ship
    else
      root.game.prepDone(true)

  addwires: (layer) =>
    wires = new Kinetic.Shape(
      drawFunc = () ->
        ctx = this.getContext()
        ctx.beginPath()
        ctx.lineWidth = 1
        ctx.strokeStyle = 'black'
        ctx.globalAlpha = 0.3
        # draw frame
        move(ctx, p0)
        line(ctx, p(10,0))
        line(ctx, p(10,10))
        line(ctx, p(0,10))
        ctx.closePath()
        # draw frame contents
        for i in [1..9]
          # draw parallel to x
          move(ctx, p(0, i))
          line(ctx, p(10, i))
          # draw parallel to y
          move(ctx, p(i, 0))
          line(ctx, p(i, 10))
        ctx.stroke()
        ctx.globalAlpha = 1.0
    )
    layer.add wires

  addbg: () =>
    @terrain = new Kinetic.Layer
    background = new Kinetic.Image(
      x: 0
      y: 0
      image: images['background']
    )
    @terrain.add background
    this.addwires @terrain
    @terrain.draw
    @stage.add @terrain

  init: (element, ready) =>
    @stage = new Kinetic.Stage 'game-canvas', canvas_w, canvas_h
    @ships = new Kinetic.Layer
    @smoke = new Kinetic.Layer
    @bomb = new Kinetic.Layer
    this.preload_images(() =>
      this.addbg()
      @stage.add @ships
      @stage.add @smoke
      @stage.add @bomb
      ready()
    )

    aim = @aim
    stage = @stage
    bomb = @bomb
    remote = @remote

    # add the aiming controls for stage
    @stage.on('mousemove', () ->
      pos = stage.getMousePosition(this)
      naim = rp(pos.x, pos.y)
      aim.x = naim.x
      aim.y = naim.y
      if remote.visible
        bomb.draw()
    )
    @stage.on('click', () ->
      if aim.x in [0..9] and aim.y in [0..9] and remote.visible and root.game.state == 'player-turn'
        root.game.fire(aim.x, aim.y)
    )

  # returns an array of prepared ships
  getShips: () =>
    ships = []
    for child in @prep_overlay.children
      if child instanceof Kinetic.Image # its a ship, ahoy!
        ships.push {
          t: child.type
          o: child.orientation
          x: child.point.x
          y: child.point.y
          s: false # sunk?
        }
    ships

  debugShips: () =>
    ships = [
      {t: 'carrier', o: 'x', x: 0, y: 0},
      {t: 'battleship', o: 'y', x: 9, y: 2},
      {t: 'battleship', o: 'y', x: 7, y: 2},
      {t: 'destroyer', o: 'y', x: 5, y: 1},
      {t: 'destroyer', o: 'x', x: 0, y: 2},
      {t: 'destroyer', o: 'x', x: 0, y: 4},
      {t: 'sub', o: 'x', x: 3, y: 2},
      {t: 'sub', o: 'x', x: 3, y: 4},
      {t: 'sub', o: 'x', x: 5, y: 3},
      {t: 'sub', o: 'x', x: 7, y: 4}
    ]

    validArea = undefined
    del = []
    for child in @prep_overlay.children
      validArea = child unless child instanceof Kinetic.Image
      del.push child

    for child in del
      @prep_overlay.remove child

    console.log @prep_overlay
    @prep_overlay.draw
    
    @prep_overlay.add validArea

    for i in [0...ships.length]
      ship = new Kinetic.Image(
        x: ships[i].x
        y: ships[i].y
        image: images[ships[i].t + '_' + ships[i].o]
      )
      ship.point = {
        x: ships[i].x
        y: ships[i].y
      }
      roundpoint = p(ship.point.x, ship.point.y)
      if (ships[i].o == 'x')
        ship.x = roundpoint.x
        ship.y = roundpoint.y - ship_h + tile_hh
      else
        ship.x = roundpoint.x - ship_w + tile_w
        ship.y = roundpoint.y - ship_h + tile_hh
      ship.type = ships[i].t
      ship.orientation = ships[i].o
      @prep_overlay.add ship
    @stage.remove @prep_overlay
    @stage.add @prep_overlay
    root.game.prepDone true

  commit_ships: (ships) =>
    console.log 'commiting ships'
    @stage.remove @prep_overlay if @prep_overlay?
    @prep_overlay = undefined # gc
    for ship in ships
      @local.ships.push ship

  start_placing: (ships) =>
    this.add_prep_overlay(ships) unless @prep_overlay?

  show_result: (result) =>
    obj =
      switch result.w
        when 'remote' then @remote
        when 'local' then @local

    if result.r == 'sunk'
      obj.smoke.push {t: 'nuke', x: result.x, y: result.y}
      obj.ships.push result.s
    else if result.r == 'miss'
      obj.smoke.push {t: 'flag', x: result.x, y: result.y}
    else if result.r == 'hit'
      obj.smoke.push {t: 'nuke', x: result.x, y: result.y}

    this.show_board result.w

  show_board: (who) =>
    console.log "show_board(#{who}, #{root.game.state})"
    if who == 'local'
      this.show_ships(@local.ships)
      this.show_smoke(@local.smoke)
      @local.visible = true
      @remote.visible = false
      # add the bomb layer for later animation
      console.log 'bomb layer for anim only'
      this.show_bomb(false)
    else
      this.show_ships(@remote.ships)
      this.show_smoke(@remote.smoke)
      @local.visible = false
      @remote.visible = true
      if root.game.state == 'player-turn'
        # add the bomb layer with aiming
        this.show_bomb(true)
        console.log 'bomb layer with anim and aim'
      else
        this.show_bomb(false)

  show_ships: (ships) =>
    @stage.remove @ships
    clear(@ships)
    for ship in ships
      draw_ship(@ships, "#{ship.t}_#{ship.o}", p(ship.x, ship.y))
    @ships.draw
    @stage.add @ships

  show_smoke: (smoke) =>
    @stage.remove @smoke
    clear(@smoke)
    for sqr in smoke
      if sqr.t == 'nuke'
        draw_nuke(@smoke, p(sqr.x, sqr.y))
      else if sqr.t == 'flag'
        draw_flag(@smoke, p(sqr.x, sqr.y))
    @smoke.draw
    @stage.add @smoke

  show_bomb: (aiming) =>
    @stage.remove @bomb

    clear(@bomb)

    if aiming
      console.log 'aiming'
      stage = @stage
      layer = @bomb
      aim = @aim

      reticle = new Kinetic.Shape(
        drawFunc = () ->
          ctx = this.getContext()
          if aim.x in [0..9] and aim.y in [0..9]
            ctx.beginPath()
            ctx.lineWidth = 4
            ctx.strokeStyle = 'black'
            ctx.globalAlpha = 1.0
            # draw reticle
            move(ctx, p(aim.x, aim.y))
            line(ctx, p(aim.x+1, aim.y))
            line(ctx, p(aim.x+1, aim.y+1))
            line(ctx, p(aim.x,   aim.y+1))
            ctx.closePath()
            ctx.stroke()
      )
      layer.add reticle

    @stage.add @bomb

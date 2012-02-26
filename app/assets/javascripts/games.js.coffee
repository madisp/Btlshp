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

# Our point zero
p0 = {
  x: game_x
  y: game_y + game_h / 2
}

# plates a (0..10, 0..10) range point
# to canvas coordinates
p = (x, y) ->
  {
    x: p0.x + x*tile_hw + y*tile_hw
    y: p0.y - x*tile_hh + y*tile_hh
  }

# convenience methods

line = (ctx, p) ->
  ctx.lineTo(p.x, p.y)

move = (ctx, p) ->
  ctx.moveTo(p.x, p.y)

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
  'bomb'
]

# preload images
preload_images = (cb) ->
  n = 0
  for src in sources
    console.log 'preloading ' + src + '.png'
    images[src] = new Image
    images[src].onload = () ->
      n += 1
      if (n >= sources.length)
        cb()
    images[src].src = '/assets/' + src + '.png'

# draw wireframes

draw_wires = (stage) ->
  layer = new Kinetic.Layer
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
  stage.add layer

#draw_tile = (layer, src, p) ->
#  tile = new Kinetic.Image(
#    x: p.x,
#    y: p.y - tile_hh,
#    image: images[src]
#  )
#  layer.add tile

#rand_ocean = () ->
#  rand = Math.ceil(Math.random() * 2)
#  'ocean_' + rand

draw_terrain = (stage) ->
  # using prerendered background instead
  # draw terrain for game area
#  for x in [0..9]
#    for y in [0..9]
#      rand = Math.ceil(Math.random() * 2)
#      draw_tile(terrain, rand_ocean(), p(x,y))

  # draw the "corners" to give a sense of space
#  for j in [-1..-5]
#    for i in [(-1-j)..10+j]
#      draw_tile(terrain, rand_ocean(), p(i,j))
#      draw_tile(terrain, rand_ocean(), p(j,i))
#      draw_tile(terrain, rand_ocean(), p(i,9-j))
#      draw_tile(terrain, rand_ocean(), p(9-j,i))
  terrain = new Kinetic.Layer
  background = new Kinetic.Image(
    x: 0
    y: 0
    image: images['background']
  )
  terrain.add(background)
  stage.add terrain

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

init_game = () ->
  console.log $('#game-canvas').length
  if $('#game-canvas').length != 0
    stage = init_canvas()
    preload_images(() -> 
      draw_terrain(stage)
      draw_wires(stage)
      draw_ships(stage)
      draw_smoke(stage)
      draw_bomb(stage, 400, 30)
    )
#  add_terrain(stage)

window.onload = () ->
  init_game()

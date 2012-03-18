root = exports ? this

class BtlGame
  board: new root.BtlBoard
  init: () =>
    console.log 'Initializing a new empty game'
    @board.init('game-canvas')

window.onload = () ->
  # look for game canvas
  if $('#game-canvas').length != 0

    game = new BtlGame

    # does it have data ?
    id = $('#game-canvas').attr('data-gameid')
    if id?
      console.log "Loading game with ID=" + id
      game.load id
    else
      console.log "No ID found, starting a new game"

    game.init()
      # game.matcher
#    g = new Game

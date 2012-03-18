root = exports ? this

class BtlGame
  board: new root.BtlBoard
  server: new root.Connection
  state: 'prep'
  player_ships: []

  prepDone: (isDone) =>
    oldState = @state
    if isDone
      @state = 'prepared'
    else
      @state = 'prep'
    this.onStateChanged() unless oldState == @state

  playerTurn: =>
    #TODO add a new gameStarted callback?
    if @state == 'prepared'
      # game started, commit changes to board
      @board.commit_ships @board.getShips()
      this.log('Game started')
      $('#board-tabs').show()
      $('#board-tabs li#local').bind('click', () =>
        this.showBoard 'local'
      )
      $('#board-tabs li#remote').bind('click', () =>
        this.showBoard 'remote'
      )
      $('#game-prepare').hide()
      $('#game-status').show()
    @state = 'player-turn'
    this.onStateChanged()

  commitBoard: =>
    ships = @board.getShips()
    @server.commitBoard ships

  onStateChanged: () =>
    console.log("State changed, new state: #{@state}")
    if @state == 'prepared'
      $('#start-btn').removeClass 'disabled'
      $('#start-btn').bind('click', this.commitBoard)
    else if @state == 'prep'
      $('#start-btn').addClass 'disabled'
      $('#start-btn').unbind('click')
    else if @state == 'player-turn'
      $('#status-head').html('Your turn')
      this.showBoard('remote')
    else if @state == 'enemy-turn'
      $('#status-head').html('XYZ\'s turn')
      this.showBoard('local')

    # update player status
    ships = @board.local.ships
    count = {
      ship: 0
      carrier: 0
      battleship: 0
      destroyer: 0
      sub: 0
    }
    for ship in ships
      count.ship += 1
      count[ship.t] += 1
    for c, v of count
      $("##{c}-count").html("" + v)

  showBoard: (who) ->
    $('#board-tabs li').removeClass 'active'
    $('#board-tabs li#' + who).addClass 'active'
    @board.show_board who

  init: () =>
    console.log 'Initializing a new empty game'
    # hide tabs
    $("#board-tabs").hide()
    @board.init('game-canvas', () =>
      ship_types = ['carrier', 'battleship', 'destroyer', 'sub']
      ships = []
      ships.push ship_types[x] for y in [0..x] for x in [0..3]
      @board.start_placing(ships)
    )
    @server.listener = this
    $("#debug-ships").bind('click', () =>
      $("#debug-ships").hide()
      @board.debugShips()
    )
  log: (msg) =>
    #TODO html-escape
    $('#game-log').append("<li>#{msg}</li>")

window.onload = () ->
  # look for game canvas
  if $('#game-canvas').length != 0

    root.game = new BtlGame

    # does it have data ?
    id = $('#game-canvas').attr('data-gameid')
    if id?
      console.log "Loading game with ID=" + id
      root.game.load id # unimplemented!
    else
      console.log "No ID found, starting a new game"

    root.game.init()

root = exports ? this

class BtlGame
  board: new root.BtlBoard
  server: new root.Connection
  state: 'prep'

  # board callbacks

  prepDone: (isDone) =>
    oldState = @state
    if isDone
      @state = 'prepared'
    else
      @state = 'prep'
    this.onStateChanged() unless oldState == @state

  fire: (x, y) =>
    if @state == 'player-turn'
      this.log("You fired at (#{x}, #{y})")
      @server.fire(x, y)

  # server callbacks
  
  result: (result) =>
    console.log result
    this.log(
      switch result.r
        when 'miss' then 'Missed'
        when 'hit' then 'Hit!'
        when 'sunk' then "Sunk #{result.s.t}"
    )

  boardValidated: (ships) =>
    @board.commit_ships ships
    this.onStateChanged()

  gameStarted: () =>
    @state = 'started'
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
    this.onStateChanged()
    this.throbber(null)

  playerTurn: () =>
    @state = 'player-turn'
    this.onStateChanged()

  # UI hooks

  commitBoard: =>
    @state = 'board-committed'
    ships = @board.getShips()
    @server.commitBoard ships
    this.throbber('Moving fleet...')
    $('#start-btn').hide()

  showBoard: (who) ->
    $('#board-tabs li').removeClass 'active'
    $('#board-tabs li#' + who).addClass 'active'
    @board.show_board who

  # State changes

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

    if @state in ['player-turn', 'enemy-turn']
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
    @server.setListener this
    $("#debug-ships").bind('click', () =>
      $("#debug-ships").hide()
      @board.debugShips()
    )

  # helper methods

  log: (msg) =>
    #TODO html-escape
    $('#game-log').prepend("<li>#{msg}</li>")

  throbber: (msg) =>
    if msg?
      $('#throbber').show()
      $('#throbber span').html(msg)
    else
      $('#throbber').hide()

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

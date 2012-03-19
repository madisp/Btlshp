root = exports ? this

# Mock implementation of server
class root.Connection
  listener: undefined

  # USED FOR MOCK AI
  playerShips: undefined
  aiShips: [
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
  playerTurns: []
  aiTurns: []

  commitBoard: (ships) =>
    # normally this would push the ship placement with AJAX
    # and the server would validate it. Currently we just
    # assume the board is valid
    @playerShips = ships

    # emulate network lag
    this.delay(500, () =>
      @listener.boardValidated(ships)
      @listener.gameStarted()
      @listener.playerTurn()
    )

  fire: (x, y) =>
    result = this.turn('remote', @playerTurns, @aiShips, x, y)
    this.delay(300, () =>
      @listener.result(result)
      if result.r in ['hit', 'sunk']
        @listener.playerTurn()
      else
        this.delay(2000, () =>
          @listener.enemyTurn()
          this.aiFire()
        )
    )

  aiFire: () =>
    x = Math.floor(Math.random() * 10)
    y = Math.floor(Math.random() * 10)
    result = this.turn('local', @aiTurns, @playerShips, x, y)
    this.delay(2000, () =>
      @listener.result(result)
      if result.r in ['hit', 'sunk']
        @listener.enemyTurn()
        this.aiFire()
      else
        this.delay(1500, () =>
          @listener.playerTurn()
        )
    )

  turn: (board, turns, ships, x, y) =>
    turns.push {x: x, y: y}
    for ship in ships
      if this.intersects(ship, x, y)
        if this.sunk(@playerTurns, ship)
          return {w: board, r: 'sunk', s: ship, x: x, y: y}
        else
          return {w: board, r: 'hit', x: x, y: y}
    {w: board, r: 'miss', x: x, y: y}
    

  setListener: (listener) =>
    @listener = listener
    console.log(@listener)

  delay: (time, func) =>
    setTimeout func, time

  # helper functions
  intersects: (ship, x, y) =>
    points = ship_points(ship)
    for _x in [points[0].x .. points[1].x]
      for _y in [points[0].y .. points[1].y]
        if x == _x and y == _y
          return true
    return false

  sunk: (turns, ship) =>
    points = ship_points(ship)
    c = 0
    for x in [points[0].x .. points[1].x]
      for y in [points[0].y .. points[1].y]
        if this.wasHit(turns, ship, x, y)
          c += 1
        else
    return c == ship_len(ship.t)

  wasHit: (turns, ship, x, y) =>
    for turn in turns
      if turn.x == x and turn.y == y
        return true
    return false

ship_len = (type) ->
  switch type
    when 'carrier' then 4
    when 'battleship' then 3
    when 'destroyer' then 2
    when 'sub' then 1

ship_points = (ship) ->
  len = ship_len(ship.t)
  switch ship.o
    when 'x' then [{x:ship.x, y:ship.y},{x:ship.x+len-1, y:ship.y}]
    when 'y' then [{x:ship.x, y:ship.y-len+1},{x:ship.x, y:ship.y}]

root = exports ? this

# Mock implementation of server
class root.Connection
  listener: undefined

  # USER FOR MOCK AI
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

  commitBoard: (ships) =>
    # normally this would push the ship placement with AJAX
    # and the server would validate it. Currently we just
    # assume the board is valid
    @playerShips = ships
    @listener.playerTurn()

  setListener: (listener) => @listener = listener

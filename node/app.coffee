
# Module dependencies.

express = require('express')
less = require('less')
http = require('http')

# used for joining websockets with express sessions
parseCookie = require('connect').utils.parseCookie
sessionStore = new express.session.MemoryStore
console.log(sessionStore)

games = []

app = express()

app.configure(() ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.favicon())
  app.use(express.logger('dev'))
  app.use(express.static(__dirname + '/public'))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(require('connect-assets')())
  app.use(express.cookieParser('keyboard cat'))
  # this should not end up in the github repo in a perfect world
  app.use(express.session({
    secret:'keyboard cat',
    store: sessionStore,
    key: 'connect.sid'
  }))
)

app.configure('development', () ->
  app.use(express.errorHandler())
)

app.get('/', (req, res) ->
  if req.session.user
    if req.session.game
      res.render 'game', {user: req.session.game}
    else
      res.render 'lobby', {user: req.session.user}
  else
    res.render 'landing', {}
)

app.get('/signin', (req, res) ->
  number = Math.round((Math.random() * 1000))
  req.session.user = "Player#{number}"
  res.redirect('/')
)

app.get('/signout', (req, res) ->
  req.session.user = undefined
  res.redirect('/')
)

server = http.createServer(app)
server.listen(3000)

io = require('socket.io').listen(server)

io.set('authorization', (data, accept) ->
  if (data.headers.cookie)
    data.cookie = parseCookie(data.headers.cookie)
    data.sessionID = data.cookie['connect.sid']
    sid = data.sessionID.split('.')[0]
    sessionStore.get(sid, (err, session) ->
      if (err || !session)
        accept('Error', false)
      else
        data.session = session
        accept(null, true)
    )
  else
    return accept('No cookie transmitted.', false)
)

io.sockets.on('connection', (socket) ->
  session = socket.handshake.session
  console.log("Player #{session.user} connected")

  if session.game
    # emit game state
  else
    # emit lobby
    socket.emit('lobby', {
      games: games
    })

  socket.on('create.game', (data) ->
    games.push {
      name: "#{session.user}'s game",
      players: [session.user]
    }
  )

  socket.on('event', (data) ->
    console.log data
  )
)

console.log("Express server listening on port 3000")

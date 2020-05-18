part of server;

typedef shelf.Pipeline Handler(shelf.Request request);

class Server {

  HttpServer httpServer;

  DbContext db;

  Timer gameDispatcher;

  Future start() async {
    db = new DbContext(new PostgresDriver('localhost', 'postgres', 'postgres', 'postgres'));
    await db.run((db) async {
      await db.players.createTable();
      await db.sessions.createTable();
      await db.games.createTable();
    });
    httpServer = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8084, shared: true);
    io.serveRequests(httpServer, createServerHandler());
    gameDispatcher = new Timer.periodic(new Duration(seconds: 10), dispatchGames);
  }

  Future stop() async {
    if (httpServer != null)
      await httpServer.close(force: true);
  }

  Handler createServerHandler() {
    Router route = router();

    initRoutes(route);

    var handler = const shelf.Pipeline()
        .addMiddleware(ExceptionHandler())
        .addMiddleware(createCorsMiddleware())
        .addMiddleware(authorize)
        .addHandler(route.handler);
    return handler;
  }

  void initRoutes(Router route) {
    route.get('/players/current', getCurrentPlayer);
    route.post('/players/current', postCurrentPlayer);

    route.get('/game/stream', webSocketHandler(gameSocket));
  }

  Future<Player> postCurrentPlayer(Player player) async {
   var currentPlayer = Context.current.session.player;
   if (currentPlayer.id == player.id) {
     currentPlayer.name = player.name;
     await db.players.save(currentPlayer);
   }
   return currentPlayer;
  }

  Future<Player> getCurrentPlayer() async => Context.current.session.player;

  Map<String, WebSocketChannel> playerConnections = {}; //<player.id, socket>
  Map<String, Game> playerGames = {}; //<player.id, game>
  Map<String, DateTime> playerActivity = {}; //<player.id, date>
  Map<String, Engine> engines = {}; //<game.id, engine>

  Player waitingPlayer;
  List<Game> waitingGames = [];
  List<Game> playingGames = [];

  int gamesMax = 4;

  Future dispatchGames(Timer timer) async {
    for (var id in playerActivity.keys.toList()) {
      if (!playingGames.any((g) => id == g.blueSide.id || id == g.redSide.id) &&
          playerActivity[id].isBefore(new DateTime.now().add(new Duration(seconds: -20)))) {
        playerConnections[id].sink.close();
        playerConnections.remove(id);
        playerActivity.remove(id);
        var game = playerGames[id];
        if (game != null) {
          playerGames.remove(id);
          var otherPlayer = game.blueSide.id == id ? game.redSide : game
              .blueSide;
          game.blueSide = otherPlayer;
          game.redSide = null;
          await queuePlayer(otherPlayer, alreadyWasQueued: true);
        }
      }
    }
    for(var g in waitingGames.toList()) {
      if (g.blueSide != null && g.redSide != null && playingGames.length < gamesMax) {
        waitingGames.remove(g);
        playingGames.add(g);
        g.started = new DateTime.now();
        var engine = new Engine();
        Timer timer;
        void checkGameEnd() {
          if (g.blueScore == 7 || g.redScore == 7 || engine.stopwatch.elapsed.inSeconds > 120) {
            if (playerConnections.containsKey(g.blueSide.id))
              playerConnections[g.blueSide.id].sink.add('game over');
            if (playerConnections.containsKey(g.redSide.id))
              playerConnections[g.redSide.id].sink.add('game over');
            timer.cancel();
            engine.stop();
            engines.remove(g.id);
            engine = null;
            playingGames.remove(g);
            playerGames.remove(g.blueSide.id);
            playerGames.remove(g.redSide.id);
            db.run((db) => db.games.save(g));
          }
        };

        void sendScore() {
          var score = 'score ${g.blueSide.name} : ${g.redSide.name} - ${g.blueScore} : ${g.redScore}';
          if (playerConnections.containsKey(g.blueSide.id))
            playerConnections[g.blueSide.id].sink.add(score);
          if (playerConnections.containsKey(g.redSide.id))
            playerConnections[g.redSide.id].sink.add(score);
        }

        engine.onBlueGoal = () {
          g.redScore++;
          sendScore();
          checkGameEnd();
        };
        engine.onRedGoal = () {
          g.blueScore++;
          sendScore();
          checkGameEnd();
        };
        engine.onGameSecond = () {
          checkGameEnd();
        };

        engines[g.id] = engine;
        engine.start();
        if (playerConnections.containsKey(g.blueSide.id))
          playerConnections[g.blueSide.id].sink.add('game blue');
        if (playerConnections.containsKey(g.redSide.id))
        playerConnections[g.redSide.id].sink.add('game red');
        sendScore();
        timer = new Timer.periodic(new Duration(milliseconds: 10), (_) {
          if (engine == null)
            timer.cancel();
          var s = engine.toBytes();
          if (g.blueSide != null && playerConnections.containsKey(g.blueSide.id))
            playerConnections[g.blueSide.id].sink.add(s);
          if (g.redSide != null && playerConnections.containsKey(g.redSide.id))
            playerConnections[g.redSide.id].sink.add(s);
        });
      }
    }
  }

  void gameSocket(WebSocketChannel socket) {
    Session session;
    socket.stream.listen((msg) async {
      if (msg is String) {
        if (msg.startsWith('token')) {
          var token = msg
              .split(' ')
              .last;
          session = await findSession(token);
          playerConnections[session.player.id] = socket;
          socket.sink.add('OK');
        } else if (msg.startsWith('queue')) {
          playerActivity[session.player.id] = new DateTime.now();
          queuePlayer(session.player);
          socket.sink.add('OK');
        } else if (msg.startsWith('player')) {
          var game = playerGames[session.player.id];
          if (game != null) {
            var engine = engines[game.id];
            var data = msg.split(' ');
            engine.setPlayerPosition(session.player.id == game.blueSide.id
                ? engine.bluePlayer
                : engine.redPlayer, double.parse(data[1]),
                double.parse(data[2]));
            playerActivity[session.player.id] = new DateTime.now();
          }
        }
      }
    });
  }

  void queuePlayer(Player player, {bool alreadyWasQueued: false}) {
    if (player == null)
      return;
    if (playerGames.containsKey(player.id) && !alreadyWasQueued) {
      //game is already made
      if (playingGames.contains(playerGames[player.id])) {
        var game = playerGames[player.id];
        playerConnections[player.id].sink.add('game ${game.blueSide.id == player.id ? 'blue' : 'red'}');
      }

    } else {
      if (waitingPlayer == null) {
        waitingPlayer = player;
      } else if (waitingPlayer.id != player.id) {
        var game1 = playerGames[waitingPlayer.id];
        var game2 = playerGames[player.id];
        Game game;
        if (game1 == null && game2 == null) {
          game = new Game()
            ..checkId();
          waitingGames.add(game);
        } else {
          var i1 = waitingGames.indexOf(game1);
          var i2 = waitingGames.indexOf(game2);
          i1 = i1 == -1 ? waitingGames.length : i1;
          i2 = i2 == -1 ? waitingGames.length : i2;
          if (i1 < i2) {
            game = game1;
            waitingGames.remove(game2);
          } else {
            game = game2;
            waitingGames.remove(game1);
          }
        }
        game
          ..blueSide = waitingPlayer
          ..redSide = player;
        playerGames[player.id] = game;
        playerGames[waitingPlayer.id] = game;
        waitingPlayer = null;

        //return game
      }
    }
  }

  shelf.Middleware createCorsMiddleware() {
    return shelf.createMiddleware(requestHandler: (shelf.Request request) {
      if (request.method == 'OPTIONS')
        return new shelf.Response.ok('', headers: corsHeaders);
      return null;
    }, responseHandler: (shelf.Response response) => response.change(headers: corsHeaders));
  }

  shelf.Handler authorize(shelf.Handler innerHandler) {
    return (shelf.Request r) async {
      var token = r.headers['Authorization'];
      if (token == null) {
        var cookie = r.headers['cookie'];
        if (cookie != null && cookie != '') {
          var m = new RegExp(r'auth=([^;]*)(;|$)').firstMatch(cookie);
          if (m != null)
            token = m.group(1);
        }
      }
      if (!r.url.path.endsWith('/stream') && token == null || token == '')
        return new shelf.Response(401);
      var session = await findSession(token);
      return runZoned(() {
        return innerHandler(r);
      }, zoneValues: {#context: new Context(session)});
    };
  }

  Future findSession(String token) async {
    var session = await db.run((db) async {
      var sessions = await db.sessions.where(
          'token = @token', {'token': token}).get();
      Session session;
      if (sessions.isNotEmpty) {
        session = sessions[0];
        session.player =
        (await db.players.where('id = @id', {'id': session.player.id})
            .get())[0];
      } else {
        session = new Session.newSession(token);
        await db.players.save(session.player);
        await db.sessions.save(session);
      }
      return session;
    });
    return session;
  }

  Map<String, String> corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Methods': 'POST,GET,DELETE,PUT,OPTIONS',
  };

}

shelf.Middleware ExceptionHandler() =>
        (shelf.Handler handler) =>
        (shelf.Request request) =>
        runZoned(() => new Future.sync(() => handler(request))
            .then((shelf.Response response) async {
          return response;
        }).catchError((x, stackTrace) {
          if (x is! shelf.HijackException) {
            print(x.toString());
            print(stackTrace.toString());
            return new shelf.Response(500,
                body: x.toString());
          } else
            throw x;
        }), onError: (x, stack) {
          //if async code throws exception after response
          if (x is! shelf.HijackException) {
            print(x);
            print(stack);
          }
        });

class Context {
  Context(this.session);
  final Session session;

  static Context get current => Zone.current[#context];
}
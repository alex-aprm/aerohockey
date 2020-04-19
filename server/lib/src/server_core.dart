part of server;

typedef shelf.Pipeline Handler(shelf.Request request);

class Server {

  HttpServer httpServer;

  DbContext db;

  Future start() async {
    db = new DbContext(new PostgresDriver('localhost', 'postgres', 'postgres', 'postgres'));
    await db.run((db) async {
      await db.players.createTable();
      await db.sessions.createTable();
      await db.games.createTable();
    });
    httpServer = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8084, shared: true);
    io.serveRequests(httpServer, createServerHandler());
  }

  Future stop() async {
    if (httpServer != null)
      await httpServer.close(force: true);
  }

  Handler createServerHandler() {
    Router route = router();

    initRoutes(route);

    var handler = const shelf.Pipeline()
        .addMiddleware(createCorsMiddleware())
        .addMiddleware(authorize)
        .addHandler(route.handler);
    return handler;
  }

  void initRoutes(Router route) {

    route.get('/players/current', getCurrentPlayer);
    route.post('/players/current', postCurrentPlayer);
//    route.get('/game/queue', getGameQueue);
//    route.post('/game/queue', postGameQueue);

/*    route.get('/game', getCurrentGame);
    route.get('/game/{id}', getGame);
    route.get('/games', getGames);
*/
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
      if (token == null || token == '')
        return new shelf.Response(401);
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

      return runZoned(() {
        return innerHandler(r);
      }, zoneValues: {#context: new Context(session)});
    };
  }

  Map<String, String> corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST,GET,DELETE,PUT,OPTIONS',
  };

}

class Context {
  Context(this.session);
  final Session session;

  static Context get current => Zone.current[#context];
}
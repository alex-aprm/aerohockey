part of server;

typedef shelf.Pipeline Handler(shelf.Request request);

class Server {

  HttpServer httpServer;

  Future start() async {
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
        .addHandler(route.handler);
    return handler;
  }

  void initRoutes(Router route) {
    route.get('/test', getTestGame);
  }

  getTestGame() async {
    var game = new Game();
    game.redScore = 1;
    game.blueScore = 2;
    game.redSide = new Player()
      ..name = 'Alice';
    game.blueSide = new Player()
      ..name = 'Bob';
    return game;
  }

  shelf.Middleware createCorsMiddleware() {
    return shelf.createMiddleware(requestHandler: (shelf.Request request) {
      if (request.method == 'OPTIONS')
        return new shelf.Response.ok('', headers: corsHeaders);
      return null;
    }, responseHandler: (shelf.Response response) => response.change(headers: corsHeaders));
  }

  Map<String, String> corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'POST,GET,DELETE,PUT,OPTIONS',
  };

}

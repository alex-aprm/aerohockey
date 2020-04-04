part of app;

class Application {

  Future init() async {
    api.getClient = () => new BrowserClient();
    var client = new api.HttpClient();

    var response = await client.get('http://localhost:8084/test');
    var game = new Game()..fromJson(response.body);

    document.body.children.clear();
    document.body.append(new HeadingElement.h1()..text = '${game.redSide.name}:${game.blueSide.name}');
    document.body.append(new HeadingElement.h2()..text = '${game.redScore}:${game.blueScore}');
  }
}
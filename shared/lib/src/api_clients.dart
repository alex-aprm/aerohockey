part of api;

String root;

GameClient get game => new GameClient();

class GameClient extends HttpClient {

  Future<Player> getCurrentPlayer() async {
    var r = await this.get('$root/players/current');
    return new Player()..fromJson(r.body);
  }

  Future<Player> setCurrentPlayer(Player p) async {
    var r = await this.post('$root/players/current', body: JSON.encode(p));
    return new Player()..fromJson(r.body);
  }

}
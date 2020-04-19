part of shared;

@AutoProperties()
class Game extends Model with $Game {

  Game();
  factory Game.fromJson(map) => new Game()..fromMap(map);

  Player blueSide;
  Player redSide;
  int blueScore = 0;
  int redScore = 0;
  DateTime started;
  DateTime ended;
  String engineId;
}

@AutoProperties()
class Player extends Model with $Player {

  Player();
  factory Player.fromJson(map) => new Player()..fromMap(map);

  String name;
  int winsCount = 0;
  int losesCount = 0;
}

@AutoProperties()
class Session extends Model with $Session {

  Session();
  factory Session.fromJson(map) => new Session()..fromMap(map);

  String token;
  Player player;
  Session.newSession(this.token) {
    player = new Player()..checkId()..name = 'Игрок';
    checkId();
  }
}
part of shared;

@AutoProperties()
class Game extends Model with $Game {
  Player blueSide;
  Player redSide;
  int blueScore = 0;
  int redScore = 0;
  DateTime started;
  DateTime ended;
  String engineId;
/*
  Map toMap() {
    return {
      'id': id,
      'blueScore': blueScore,
      'redScore': redScore,
      'blueSide': blueSide?.toMap(),
      'redSide': redSide?.toMap(),
      'started': started?.toUtc()?.toIso8601String(),
      'ended': ended?.toUtc()?.toIso8601String(),
      'engineId': engineId,
    };
  }

  void fromMap(Map map) {
    id = map['id'];
    blueScore = map['blueScore'];
    redScore = map['redScore'];
    blueSide = new Player()..fromMap(map['blueSide']);
    redSide = new Player()..fromMap(map['redSide']);
    started = parseDateTime(map['started']);
    ended = parseDateTime(map['ended']);
    engineId = map['engineId'];
  }*/

}

@AutoProperties()
class Player extends Model with $Player{
  String name;
  int winsCount = 0;
  int losesCount = 0;
}
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
}

@AutoProperties()
class Player extends Model with $Player {
  String name;
  int winsCount = 0;
  int losesCount = 0;
}

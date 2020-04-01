// GENERATED CODE - DO NOT MODIFY BY HAND

part of shared;

// **************************************************************************
// Generator: PropertyGenerator
// **************************************************************************

Map<String, ModelConstructor> ModelConstructors = {
  "Game": () => new Game(),
  "Player": () => new Player()
};

class $Game {
  List<ModelProperty> properties = [
    new ModelProperty("Player", "blueSide", (model) => model.blueSide,
        (model, value) => model.blueSide = value),
    new ModelProperty("Player", "redSide", (model) => model.redSide,
        (model, value) => model.redSide = value),
    new ModelProperty("int", "blueScore", (model) => model.blueScore,
        (model, value) => model.blueScore = value),
    new ModelProperty("int", "redScore", (model) => model.redScore,
        (model, value) => model.redScore = value),
    new ModelProperty("DateTime", "started", (model) => model.started,
        (model, value) => model.started = value),
    new ModelProperty("DateTime", "ended", (model) => model.ended,
        (model, value) => model.ended = value),
    new ModelProperty("String", "engineId", (model) => model.engineId,
        (model, value) => model.engineId = value),
    new ModelProperty("String", "id", (model) => model.id,
        (model, value) => model.id = value),
  ];
}

class $Player {
  List<ModelProperty> properties = [
    new ModelProperty("String", "name", (model) => model.name,
        (model, value) => model.name = value),
    new ModelProperty("int", "winsCount", (model) => model.winsCount,
        (model, value) => model.winsCount = value),
    new ModelProperty("int", "losesCount", (model) => model.losesCount,
        (model, value) => model.losesCount = value),
    new ModelProperty("String", "id", (model) => model.id,
        (model, value) => model.id = value),
  ];
}

part of app;

class Application {

  Application() {
    api.getClient = () => new BrowserClient();
    api.root = 'http://localhost:8084';
  }

  CanvasElement field;

  SpanElement debug = new SpanElement();

  Player currentPlayer;

  Future init() async {
    var token = window.localStorage['authToken'] ?? Model.randomString(128);
    window.localStorage['authToken'] = token;
    api.token = token;
    currentPlayer = await api.game.getCurrentPlayer();
    print(currentPlayer.name);
    document.body.children.clear();
    var playerDiv = new DivElement();
    var playerNameH = new HeadingElement.h1()..text = currentPlayer.name;
    var changeNameLink = new AnchorElement()..href = '#'..text = 'поменять имя';
    changeNameLink.onClick.listen((e) {
      e.preventDefault();
      playerNameH.remove();
      var editor = new InputElement()..value = currentPlayer.name;
      var okButton = new ButtonElement()..text = 'OK';
      var cancelButton = new ButtonElement().. text = 'Отмена';
      okButton.onClick.listen((_) async {
        currentPlayer.name = editor.value;
        await api.game.setCurrentPlayer(currentPlayer);
        playerNameH.text = currentPlayer.name;
        playerDiv.children.clear();
        playerDiv.children.addAll([playerNameH, changeNameLink]);
      });
      cancelButton.onClick.listen((_) {
        playerDiv.children.clear();
        playerDiv.children.addAll([playerNameH, changeNameLink]);
      });

      playerDiv.children.clear();
      playerDiv.children.addAll([editor, okButton, cancelButton]);
    });

    document.body.append(playerDiv..children.addAll([playerNameH, changeNameLink]));
  }

  Future startGame() async {
    document.body.children.clear();
    var engine = new Engine();
    engine.start();
    field = new CanvasElement(width: engine.field.width.round(), height: engine.field.height.round());
    field.style.cursor = 'none';
    field.onMouseMove.listen((me) {
      engine.setPlayerPosition(engine.bluePlayer, me.client.x * engine.field.width / field.clientWidth,
          me.client.y * engine.field.height / field.clientHeight);
    });

    var rnd = new math.Random();
    var btn = new ButtonElement()..text = 'BOOM';
    btn.onClick.listen((_) {
      engine.puck.speedX = 700;//rnd.nextInt(2000)-1000;
      engine.puck.speedY = 0;//rnd.nextInt(2000)-100;
      engine.puck.spin = 0;//rnd.nextDouble()*40 - 20;
    });
    document.body.append(field);
    document.body.append(btn);
    document.body.append(debug);
    new Timer.periodic(new Duration(milliseconds: 1), (_) => drawField(engine));
  }

  Future drawField(Engine engine) async {
    debug.text = 'a = ${engine.bluePlayer.actualSpeed}';
    var ctx = field.context2D;
    ctx.setFillColorRgb(255, 255, 255);
    ctx.fillRect(0,0, engine.field.width, engine.field.height);
    ctx.setFillColorRgb(240, 240, 240);
    ctx.fillRect(engine.field.border, engine.field.border, engine.field.width - 2 * engine.field.border, engine.field.height - 2 * engine.field.border);
    ctx.setFillColorRgb(0, 255, 0);
    ctx.beginPath();
    ctx.ellipse(engine.puck.x, engine.puck.y, engine.puck.radius, engine.puck.radius, 0, 0, 2 * math.PI, false);
    ctx.fill();
    ctx.beginPath();
    ctx.moveTo(engine.puck.x, engine.puck.y);
    ctx.lineTo(engine.puck.x + math.cos(engine.puck.phi)*engine.puck.radius, engine.puck.y + math.sin(engine.puck.phi)*engine.puck.radius);
    ctx.stroke();

    ctx.setFillColorRgb(0, 0, 255);
    ctx.beginPath();
    ctx.ellipse(engine.bluePlayer.x, engine.bluePlayer.y, engine.bluePlayer.radius, engine.bluePlayer.radius, 0, 0, 2 * math.PI, false);
    ctx.fill();

  }

}
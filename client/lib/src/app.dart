part of app;

class Application {

  Application() {
    api.getClient = () => new BrowserClient();
    api.root = 'http://localhost:8084';
  }

  CanvasElement field;

  Player currentPlayer;

  Future init() async {
    var token = cookie.get('authToken') ?? Model.randomString(128);
    cookie.set('authToken', token, path: '/', expires: new DateTime(2222));
    api.token = token;
    currentPlayer = await api.game.getCurrentPlayer();
    document.body.children.clear();

    document.body.append(getNameDiv());
    await createSocket();
  }

  Future createSocket() async {
    var ws = new WebSocket('${api.wsRoot}/game/stream');

    StreamSubscription onCloseSub;

    void scheduleReconnect([int timeout = 0]) {
      onCloseSub.cancel();
      ws.close();
      new Timer(new Duration(seconds: timeout), () => createSocket());
    }

    Future send(dynamic data) async {
      ws.send(data);
      var c = new Completer();
      var timeout = new Timer(
          new Duration(seconds: 5), () => c.completeError('Timeout'));
      StreamSubscription sub;
      sub = ws.onMessage.listen((MessageEvent e) {
        if (e.data is String && e.data == 'OK') {
          c.complete();
          timeout.cancel();
          if (sub != null)
            sub.cancel();
        }
      });
      return c.future;
    }

    onCloseSub = ws.onClose.listen((e) {
      scheduleReconnect();
    });

    ws.onOpen.listen((e) async {
      await send('token ${api.token}');
      await send('queue');
    });

    ws.onError.listen((e) {
      scheduleReconnect(5);
    });

    var t = new Timer.periodic(new Duration(seconds: 5), (_) => send('queue'));

    ws.onMessage.listen((MessageEvent e) async {
      if (e.data is String) {
        if (e.data.startsWith('game')) {
          var color = e.data.substring(5);
          print(color);
          t.cancel();
          await startGame();
          field.onMouseMove.listen((me) async {
            var x = me.client.x * engine.field.width / field.clientWidth;
            var y = me.client.y * engine.field.height / field.clientHeight;
            engine.setPlayerPosition(
                color == 'blue' ? engine.bluePlayer : engine.redPlayer, x, y);
            var s = 'player $x $y';
            ws.send(s);
          });
        } else if (e.data.startsWith('engine')) {
           engine.fromString(e.data.substring(7));
        }
      }
    });
  }

  DivElement getNameDiv() {
    var playerDiv = new DivElement();
    var playerNameH = new HeadingElement.h1()..text = currentPlayer.name;
    var changeNameLink = new AnchorElement()..href = '#'..text = 'поменять имя';
    playerDiv.children.addAll([playerNameH, changeNameLink]);
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
    return playerDiv;
  }

  Engine engine;

  Future startGame() async {
    document.body.children.clear();
    engine = new Engine();
    engine.start();
    field = new CanvasElement(width: engine.field.width.round(), height: engine.field.height.round());
    field.style.cursor = 'none';
    document.body.append(field);
    new Timer.periodic(new Duration(milliseconds: 10), (_) => drawField(engine));
  }

  Future drawField(Engine engine) async {
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

    ctx.setFillColorRgb(255, 0, 0);
    ctx.beginPath();
    ctx.ellipse(engine.redPlayer.x, engine.redPlayer.y, engine.redPlayer.radius, engine.redPlayer.radius, 0, 0, 2 * math.PI, false);
    ctx.fill();

  }

}
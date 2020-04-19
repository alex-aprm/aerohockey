part of shared;

class Engine {
  double friction = 0.001;

  double frame = 1000000.0;

  Stopwatch stopwatch;
  int lastProcessedTick = 0;

  PlayerPuck redPlayer;
  PlayerPuck bluePlayer;
  Puck puck;
  Field field = new Field();

  String toString() => '${puck.toString()} ${bluePlayer.toString()} ${redPlayer.toString()}';

  int fromString(String s) {
    var data = s.split(' ').map((c) => double.parse(c)).toList();
    var c = puck.fromList(data);
    c += bluePlayer.fromList(data.skip(c).toList());
    c += redPlayer.fromList(data.skip(c).toList());
    return c;
  }

  void start() {
    init();
    stopwatch.start();
    processTick();
  }

  void init() {
    stopwatch = new Stopwatch();
    bluePlayer = new PlayerPuck(50.0, 50.0, field.width / 2, field.height * 3 / 4);
    redPlayer = new PlayerPuck(50.0, 50.0, field.width / 2, field.height * 1 / 4);
    puck = new Puck(30.0, 30.0, field.width / 2, field.height / 2);
    puck.speedX = 10.0;
    puck.spin = 2 * math.PI;
  }

  void setPlayerPosition(PlayerPuck player, double x, double y) {
    player.desiredX = x;
    player.desiredY = y;
  }

  Future processTick() async {
    if (stopwatch == null) return;

    var elapsedTotal = stopwatch.elapsedMicroseconds;
    var elapsedTicks = elapsedTotal - lastProcessedTick;
    lastProcessedTick = elapsedTotal;

    puck.process(elapsedTicks, this);
    bluePlayer.process(elapsedTicks, this);
    redPlayer.process(elapsedTicks, this);

    Timer.run(processTick);
  }
}

class Puck {
  void process(int elapsedTicks, Engine engine) {
    var field = engine.field;
    double newX = x + speedX * elapsedTicks / engine.frame;
    double newY = y + speedY * elapsedTicks / engine.frame;
    phi += spin * elapsedTicks / engine.frame;

    while (phi < 0) phi += 2 * math.PI;
    while (phi >= 2 * math.PI) phi -= 2 * math.PI;

    if (speedX < 0) {
      if (newX - radius <= field.border) {
        newX += 2 * (field.border - (newX - radius));
        speedX = -speedX;
        speedY += speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedX > 0) {
      if (newX + radius >= field.width - field.border) {
        newX -= 2 * ((newX + radius) - (field.width - field.border));
        speedX = -speedX;
        speedY -= speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedY < 0) {
      if (newY - radius <= field.border) {
        newY += 2 * (field.border - (newY - radius));
        speedY = -speedY;
        speedX -= speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedY > 0) {
      if (newY + radius >= field.height - field.border) {
        newY -= 2 * ((newY + radius) - (field.height - field.border));
        speedY = -speedY;
        speedX += speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speed > 0) {
      var newSpeed = (speed - speed * speed * engine.friction * elapsedTicks / engine.frame).clamp(0, double.INFINITY);
      speedX = speedX * newSpeed / speed;
      speedY = speedY * newSpeed / speed;
    }

    if (spin != 0)
      spin = (spin.abs() - 100 * (spin * spin) * engine.friction * elapsedTicks / engine.frame).clamp(0, double.INFINITY) *
          spin.abs() /
          spin;

    x = newX;
    y = newY;
  }

  String toString() => '$x $y $phi $speedX $speedY $spin $weight $size';

  int fromList(List<double> data) {
    x = data[0];
    y = data[1];
    phi = data[2];
    speedX = data[3];
    speedY = data[4];
    spin = data[5];
    weight = data[6];
    size = data[7];
    return 8;
  }

  double x;
  double y;
  double phi = 0.0;

  double speedX = 0.0;
  double speedY = 0.0;

  double get impulse => weight * speed;

  double get speed => math.sqrt(speedX * speedX + speedY * speedY);
  double spin = 0.0;

  double weight;
  double size;

  double get radius => size / 2;

  double get angle  {
    if (speedY <= 0)
      return math.acos(speedX / speed);
    else
      return  math.PI + math.acos(- speedX / speed);
  }

  Puck(this.size, this.weight, this.x, this.y);
}

class PlayerPuck extends Puck {
  PlayerPuck(double size, double weight, this.desiredX, this.desiredY) : super(size, weight, desiredX, desiredY);

  String toString() => '${super.toString()} $desiredX $desiredY $actualSpeed';

  int fromList(List<double> data) {
    var c = super.fromList(data);
    desiredX = data[c];
    desiredY = data[c + 1];
    actualSpeed = data[c + 2];
    return c + 3;
  }
  
  double desiredX;
  double desiredY;
  double actualSpeed = 0.0;

  void process(int elapsedTicks, Engine engine) {
    desiredX = desiredX.clamp(engine.field.border + radius, engine.field.width - engine.field.border - radius);
    desiredY = desiredY.clamp(engine.field.border + radius, engine.field.height - engine.field.border - radius);
    if (desiredX != x) speedX = (desiredX - x) * 100;
    if (desiredY != y) speedY = (desiredY - y) * 100;

    var newX = x + speedX * elapsedTicks / engine.frame;
    var newY = y + speedY * elapsedTicks / engine.frame;

    var puck = engine.puck;
    var distance = math.sqrt((puck.x - newX) * (puck.x - newX) + (puck.y - newY) * (puck.y - newY));
    if (distance < radius + puck.radius) {
      var newPuckSpeed = 10 * engine.friction * (puck.speed) + actualSpeed ;
      var sx = puck.x - newX;
      var sy = puck.y - newY;
      var s = math.sqrt(sx * sx + sy * sy);
      sx = sx / s;
      sy = sy / s;

      puck.speedX = sx * newPuckSpeed;
      puck.speedY = sy * newPuckSpeed;

      if (actualSpeed > 0) {
        var angle = this.angle - puck.angle;
        puck.spin = 100 * angle * actualSpeed * elapsedTicks / engine.frame;
      }

      var vx = newX - puck.x;
      var vy = newY - puck.y;

      puck.x += (newX - x);
      puck.y += (newY - y);
      puck.x = puck.x.clamp(engine.field.border + puck.radius, engine.field.width - engine.field.border - puck.radius);
      puck.y = puck.y.clamp(engine.field.border + puck.radius, engine.field.height - engine.field.border - puck.radius);



      vx = vx / distance * (radius + puck.radius - distance);
      vy = vy / distance * (radius + puck.radius - distance);
      newX += vx;
      newY += vy;
      x = newX;
      y = newY;

    }

    actualSpeed = math.sqrt((newX - x) * (newX - x) + (newY - y) * (newY - y)) * engine.frame / elapsedTicks;
    x = newX;
    y = newY;
  }
}

class Field {
  double width = 500.0;
  double height = 800.0;
  double border = 20.0;
  double gateWidth = 300.0;
}

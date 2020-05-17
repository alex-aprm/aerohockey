part of shared;

typedef void OnGoal();

class Engine {
  double friction = 0.001;

  OnGoal onBlueGoal;
  OnGoal onRedGoal;
  OnGoal onGameSecond;

  int goalTime;

  double frame = 1000000.0;

  Stopwatch stopwatch;
  int lastProcessedTick = 0;
  int gameSecondElapsed = 0;
  int lastLoadedTick = 0;

  PlayerPuck redPlayer;
  PlayerPuck bluePlayer;
  Puck puck;
  Field field = new Field();

  String toString() => '$lastProcessedTick ${puck.toString()} ${bluePlayer.toString()} ${redPlayer.toString()}';

  int fromString(String s) {
    var data = s.split(' ').map((c) => double.parse(c)).toList();
    if (lastLoadedTick > data[0])
      return 0;
    lastLoadedTick = data[0];
    var c = puck.fromList(data.skip(1).toList()) + 1;
    c += bluePlayer.fromList(data.skip(c).toList());
    c += redPlayer.fromList(data.skip(c).toList());
    return c;
  }

  void start() {
    init();
    stopwatch.start();
    processTick();
  }

  void stop() {
    stopwatch = null;
  }

  void goal() {
    goalTime = stopwatch.elapsedMicroseconds;
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
    gameSecondElapsed += elapsedTicks;
    lastProcessedTick = elapsedTotal;

    if (gameSecondElapsed > 1e6) {
      if (onGameSecond != null)
        onGameSecond();
      gameSecondElapsed = 0;
    }

    puck.process(elapsedTicks, this);
    bluePlayer.process(elapsedTicks, this);
    redPlayer.process(elapsedTicks, this);

    if (goalTime != null && elapsedTotal - goalTime > 2000000) {
      goalTime = null;
      puck.x = field.width / 2;
      puck.y = field.height /2;
      puck.speedY = 0.0;
      puck.speedX = 0.0;
    }

    Timer.run(processTick);
  }
}

class Puck {

  void process(int elapsedTicks, Engine engine) {
    if (engine.goalTime != null)
      return;
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
        var cornerX = field.width / 2 - field.gateWidth / 2;
        if (newX < cornerX || newX > field.width - cornerX) {
          newY += 2 * (field.border - (newY - radius));
          speedY = -speedY;
          speedX -= speed * spin * elapsedTicks / engine.frame;
        }  else {
          if (newX - radius < cornerX) {
            var x = speed * (newX - cornerX) / radius;
            var y = math.sqrt(speed*speed - x*x);
            speedX = x;
            speedY = y;
          } else if (newX + radius> field.width - cornerX) {
            var x = speed * (newX - field.width + cornerX) / radius;
            var y = math.sqrt(speed * speed - x * x);
            speedX = x;
            speedY = y;
          } else {
            if (newY + radius < 0) {
              engine.goal();
              if (engine.onRedGoal != null)
                engine.onRedGoal();
            }
          }
        }
      }
    }

    if (speedY > 0) {
      if (newY + radius >= field.height - field.border) {
        var cornerX = field.width / 2 - field.gateWidth / 2;
        if (newX < cornerX || newX > field.width - cornerX) {
          newY -= 2 * ((newY + radius) - (field.height - field.border));
          speedY = -speedY;
          speedX += speed * spin * elapsedTicks / engine.frame;
        } else {
          if (newX - radius < cornerX) {
            var x = speed * (newX - cornerX) / radius;
            var y = math.sqrt(speed*speed - x*x);
            speedX = x;
            speedY = -y;
          } else if (newX + radius> field.width - cornerX) {
            var x = speed * (newX - field.width + cornerX) / radius;
            var y = math.sqrt(speed * speed - x * x);
            speedX = x;
            speedY = -y;
          } else {
            if (newY - radius > field.height) {
              engine.goal();
              if (engine.onBlueGoal != null)
                engine.onBlueGoal();
            }
          }
        }
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

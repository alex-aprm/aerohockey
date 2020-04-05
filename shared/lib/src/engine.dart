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

  void start() {
    stopwatch = new Stopwatch();
    stopwatch.start();
    bluePlayer = new PlayerPuck(50.0, 50.0, field.width / 2, field.height * 3 / 4);

    puck = new Puck(30.0, 30.0, field.width / 2, field.height / 2);
    puck.spin = 2 * math.PI;

    processTick();
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

  double desiredX;
  double desiredY;
  double actualSpeed;
  bool collision = false;

  void process(int elapsedTicks, Engine engine) {
    desiredX = desiredX.clamp(engine.field.border + radius, engine.field.width - engine.field.border - radius);
    desiredY = desiredY.clamp(engine.field.border + radius, engine.field.height - engine.field.border - radius);
    if (desiredX != x) speedX = (desiredX - x) * 100;
    if (desiredY != y) speedY = (desiredY - y) * 100;

    var newX = x + speedX * elapsedTicks / engine.frame;
    var newY = y + speedY * elapsedTicks / engine.frame;

    collision = false;
    var puck = engine.puck;
    var distance = math.sqrt((puck.x - newX) * (puck.x - newX) + (puck.y - newY) * (puck.y - newY));
    if (distance < radius + puck.radius) {
      collision = true;
      var newPuckSpeed = engine.friction * (puck.speed) + actualSpeed ;
      var sx = puck.x - newX;
      var sy = puck.y - newY;
      var s = math.sqrt(sx * sx + sy * sy);
      sx = sx / s;
      sy = sy / s;

      puck.speedX = sx * newPuckSpeed;
      puck.speedY = sy * newPuckSpeed;

      if (actualSpeed > 0) {
        var angle = this.angle - puck.angle;
        puck.spin = angle * actualSpeed * elapsedTicks / engine.frame;
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

part of shared;

class Engine {
  double friction = 0.2;

  double frame = 1000000.0;

  Stopwatch stopwatch;
  int lastProcessedTick = 0;

  Puck redPlayer;
  Puck bluePlayer;
  Puck puck;
  Field field = new Field();

  void start() {
    stopwatch = new Stopwatch();
    stopwatch.start();
    redPlayer = new Puck(50.0, 50.0);
    puck = new Puck(30.0, 30.0);
    puck.x = field.width / 2;
    puck.y = field.height / 2;
    puck.spin = 2 * math.PI;

    processTick();
  }

  Future processTick() async {
    if (stopwatch == null)
      return;

    var elapsedTotal = stopwatch.elapsedMicroseconds;
    var elapsedTicks = elapsedTotal - lastProcessedTick;
    lastProcessedTick = elapsedTotal;

    puck.process(elapsedTicks, this);

    Timer.run(processTick);
  }
}

class Puck {

  void process(int elapsedTicks, Engine engine) {
    var field = engine.field;
    double newX = x + speedX * elapsedTicks / engine.frame;
    double newY = y + speedY * elapsedTicks / engine.frame;
    phi += spin * elapsedTicks / engine.frame;

    while (phi < 0 )
      phi += 2* math.PI;
    while (phi >= 2* math.PI )
      phi -= 2* math.PI;

    var speed = math.sqrt(speedX * speedX + speedY * speedY);

    if (speedX < 0) {
      if (newX - radius <= field.border) {
        newX += 2*(field.border - (newX - radius));
        speedX = - speedX;
        speedY += 0.5 * speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedX > 0) {
      if (newX + radius >= field.width - field.border) {
        newX -= 2*((newX + radius) - (field.width - field.border));
        speedX = - speedX;
        speedY -= 0.5 * speed* spin * elapsedTicks / engine.frame;
      }
    }

    if (speedY < 0) {
      if (newY - radius <= field.border) {
        newY += 2*(field.border - (newY - radius));
        speedY = - speedY;
        speedX -= 0.5 * speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedY > 0) {
      if (newY + radius >= field.height - field.border) {
        newY -= 2*((newY + radius) - (field.height - field.border));
        speedY = - speedY;
        speedX += 0.5 * speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speed > 0) {
      var newSpeed = (speed - 2000 * engine.friction * elapsedTicks / engine.frame).clamp(0, double.INFINITY);
      speedX = speedX * newSpeed / speed;
      speedY = speedY * newSpeed / speed;
    }

    if (spin != 0)
      spin = (spin.abs() - 20*engine.friction * elapsedTicks / engine.frame).clamp(0, double.INFINITY) * spin.abs() / spin;

    x = newX;
    y = newY;
  }

  double x;
  double y;
  double phi = 0.0;

  double speedX = 0.0;
  double speedY = 0.0;
  double spin = 0.0;

  double weight;
  double size;
  double get radius => size / 2;

  Puck(this.size, this.weight);
}

class Field {
  double width = 500.0;
  double height = 800.0;
  double border = 20.0;
  double gateWidth = 300.0;
}
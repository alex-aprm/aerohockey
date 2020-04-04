part of shared;

class Engine {
  double friction = 0.4;

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
    if (stopwatch == null)
      return;

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

    while (phi < 0 )
      phi += 2* math.PI;
    while (phi >= 2* math.PI )
      phi -= 2* math.PI;

    if (speedX < 0) {
      if (newX - radius <= field.border) {
        newX += 2*(field.border - (newX - radius));
        speedX = - speedX;
        speedY +=  speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedX > 0) {
      if (newX + radius >= field.width - field.border) {
        newX -= 2*((newX + radius) - (field.width - field.border));
        speedX = - speedX;
        speedY -=  speed* spin * elapsedTicks / engine.frame;
      }
    }

    if (speedY < 0) {
      if (newY - radius <= field.border) {
        newY += 2*(field.border - (newY - radius));
        speedY = - speedY;
        speedX -= speed * spin * elapsedTicks / engine.frame;
      }
    }

    if (speedY > 0) {
      if (newY + radius >= field.height - field.border) {
        newY -= 2*((newY + radius) - (field.height - field.border));
        speedY = - speedY;
        speedX +=  speed * spin * elapsedTicks / engine.frame;
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

  double get impulse => weight * speed;

  double get speed => math.sqrt(speedX * speedX + speedY * speedY);
  double spin = 0.0;

  double weight;
  double size;
  double get radius => size / 2;

  Puck(this.size, this.weight, this.x, this.y);
}


class PlayerPuck extends Puck {
  PlayerPuck(double size, double weight, this.desiredX, this.desiredY): super(size, weight, desiredX, desiredY);

  double desiredX;
  double desiredY;

  void process(int elapsedTicks, Engine engine) {
    desiredX = desiredX.clamp(engine.field.border + radius, engine.field.width - engine.field.border - radius);
    desiredY = desiredY.clamp(engine.field.border + radius, engine.field.height - engine.field.border - radius);
    if (desiredX != x)
      speedX = (desiredX - x) * 100;
    if (desiredY != y)
      speedY = (desiredY - y) * 100;


    var newX = x + speedX * elapsedTicks / engine.frame;
    var newY = y + speedY * elapsedTicks / engine.frame;

    var puck = engine.puck;
    var distance = math.sqrt((puck.x - newX) * (puck.x - newX) + (puck.y - newY) * (puck.y - newY));
    if (distance <= radius + puck.radius) {
      var imp = (impulse > puck.impulse ? impulse : puck.impulse).clamp(0, 100000);
      var newPuckSpeed = engine.friction * imp / puck.weight;
      puck.speedX = puck.x - newX;
      puck.speedY = puck.y - newY;
      var sx = puck.speedX / puck.speed;
      var sy = puck.speedY / puck.speed;

      puck.speedX = sx * newPuckSpeed;
      puck.speedY = sy * newPuckSpeed;

      var angle = math.acos(speedX/speed) - math.acos(puck.speedX/puck.speed);

      puck.spin = angle*puck.speed/50;

    }
    else{
      x = newX;
      y = newY;
    }

  }


}

class Field {
  double width = 500.0;
  double height = 800.0;
  double border = 20.0;
  double gateWidth = 300.0;
}
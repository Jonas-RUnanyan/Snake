class Segment {
  float posX, posY;
  float followX, followY;
  float distance;
  Segment(float x, float y, float anchorX, float anchorY, float distanceP) {
    posX = x;
    posY = y;
    followX = anchorX;
    followY = anchorY;
    distance = distanceP;
  }

  void drag(float newAnchorX, float newAnchorY) {
    followX = newAnchorX;
    followY = newAnchorY;
    follow();
  }

  void follow() {
    PVector path = new PVector(followX - posX, followY - posY);
    float realDistance = path.mag();
    path.setMag(realDistance-distance);

    posX+=path.x;
    posY+=path.y;
  }

  float getPosX() {
    return posX;
  }

  float getPosY() {
    return posY;
  }
  
  PVector getPos(){
    return new PVector(posX, posY);
  }

  PVector getPoint(float theta) {
    PVector front = new PVector(posX - followX, posY - followY);
    front.rotate(theta);
    front.div(2);
    front.x+=posX;
    front.y+=posY;
    return front;
  }
}

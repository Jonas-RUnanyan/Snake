

class Fruit {
  float x,y;
  int points;
  int size;
  
  Fruit(){
    x = -20;
    y = -20;
    }
    
  void place(){
    points = (int)random(1,6);
    size = points*7+10;
    x = random(size/2, width-size/2);
    y = random(size/2, height-size/2);
  }
  
  int eat(){
    x = -20;
    y = -20;
    return points;
  }
}

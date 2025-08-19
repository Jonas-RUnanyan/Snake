import processing.sound.*;
import processing.opengl.*;

float x, y;
float vx=0, vy=0;
final int MAX_SIZE = 800;
int current_size = 20;
Segment[] segments = new Segment[MAX_SIZE];
float maxAngle = HALF_PI*0.3;
boolean[][] keys = new boolean[2][2];

ArrayList<PVector> leftSide = new ArrayList<PVector>();
PShape outline;
PVector closer;
PVector[] face = new PVector[2];

color startColor =color(122, 65, 192);
color endColor =color(63, 241, 247);
color[] fruitColors = {color(0), color(255, 0, 0), color(255, 128, 0), color(255, 255, 0), color(0, 255, 0), color(0, 0, 255)};

final int MAX_FRUITS = 15;
ArrayList<Fruit> fruitPool = new ArrayList<Fruit>();
ArrayList<Fruit> activeFruits = new ArrayList<Fruit>();

int score = 0;

color backgroundColor = color(random(200, 256), random(200, 256), random(200, 256));
int colorIndex=0;

final int PLAYING = 0;
final int GAME_OVER = 1;
int GAMESTATE = PLAYING;

final int GAME_OVER_TIME = 100;
int gameOverTimer = 0;

PShape tongue;



void setup() {
  setup_sound();
  size(800, 600, OPENGL);
  colorMode(HSB, 360, 100, 100);
  smooth(0);
  ellipseMode(CENTER);
  shapeMode(CENTER);
  x = width/2;
  y = height/2;
  for (int i=0; i<segments.length; i++) {
    segments[i] = new Segment(0, 0, 0, 0, getGirth(i));
  }
  for (int i = 0; i<MAX_FRUITS; i++) {
    fruitPool.add(new Fruit());
  }

  noStroke();
  
  textAlign(CENTER);
  tongue = loadShape("data/tongue.svg");
}

void draw() {
  switch(GAMESTATE) {
  case PLAYING:
  
    //every 20 points, we change the background color, and set the snake's head color to its complementary. The backgroud chord is also changed
    if (colorIndex!=score/20) {
      int hue = (int)random(0, 361);
      backgroundColor = color(hue, random(0, 50), random(70, 90));
      startColor = color((hue+180)%360, 100, 100);
      colorIndex = score/20;
      play_bass_note();
    }
    
    //color background and write text
    background(backgroundColor);
    fill(50);
    textSize(100);
    textAlign(CENTER);
    text(score, width/2, height/4);
    textSize(20);
    textAlign(LEFT);
    text(current_chord, 10, 20);
    textSize(100);
    textAlign(RIGHT);

    leftSide = new ArrayList();

    manage_fruits();

    outline = createShape();
    beginShape(POLYGON);

    fill(0, 0, 255);

    //we move the snake according to the input
    move();

    x+=vx;
    y+=vy;

    
    for (int i=0; i<current_size; i++) {
      if (i==0) {
        segments[0].drag(x, y);
        for (float j = HALF_PI; j<=3*HALF_PI; j+=HALF_PI/2) {

          PVector head = segments[0].getPoint(j);
          
          if(j==PI){
            PVector direction = new PVector(head.y-y,x-head.x);
            translate(x,y);
            rotate(direction.heading());          
            shape(tongue, 0,10,10,20);
            popMatrix();
            }

          if (j==1.5*HALF_PI) {
            face[0] = head;
          } else if (j==2.5*HALF_PI) {
            face[1] = head;
          }

          curveVertex(head.x, head.y);
          if (j==HALF_PI) {
            fill(startColor);
            curveVertex(head.x, head.y);
            closer=head;
            
            pushMatrix();
            
          }
        }
      } else {
        segments[i].drag(segments[i-1].getPosX(), segments[i-1].getPosY());
        
        // Limitar el ángulo si no estamos en el último
        if (i < segments.length - 1) {
          PVector a = new PVector(segments[i - 1].posX, segments[i - 1].posY);
          PVector b = new PVector(segments[i].posX, segments[i].posY);
          PVector c = new PVector(segments[i + 1].posX, segments[i + 1].posY);

          PVector ab = PVector.sub(b, a).normalize();
          PVector bc = PVector.sub(c, b).normalize();

          float angle = PVector.angleBetween(ab, bc);

          if (angle > maxAngle) {

            // Calculamos si el giro es horario o antihorario
            float cross = ab.x * bc.y - ab.y * bc.x;
            float sign = (cross < 0) ? -1 : 1;

            // Corregir dirección
            bc = ab.copy();
            bc.rotate(sign * maxAngle);

            // Reposicionar el segmento [i+1] en la nueva dirección
            bc.mult(segments[i + 1].distance);
            segments[i + 1].posX = b.x + bc.x;
            segments[i + 1].posY = b.y + bc.y;
          }
        }
        
        //we skip the first 5 segments in order to avoid unexpected behaviour
        if(i>5)
          calculate_collisions_with_fruits(i);
        
        PVector left = segments[i].getPoint(HALF_PI);
        PVector right = segments[i].getPoint(-HALF_PI);
        fill(255, 0, 0);
        leftSide.add(left);
        fill(0, 0, 255);
        fill(lerpColor(startColor, endColor, (float)i/(float)current_size));
        curveVertex(right.x, right.y);
        if (segments[0].getPos().dist(segments[i].getPos())<10) {
          game_over();
        }
      }
    }
    PVector tail = segments[current_size-1].getPoint(0);
    fill(endColor);
    curveVertex(tail.x, tail.y);


    for (int i=leftSide.size()-1; i>=0; i--) {
      fill(lerpColor(startColor, endColor, (float)i/(float)current_size));
      curveVertex(leftSide.get(i).x, leftSide.get(i).y);
    }

    curveVertex(closer.x, closer.y);
    curveVertex(closer.x, closer.y);

    endShape(CLOSE);

    fill(0);
    circle(face[0].x, face[0].y, 7);
    circle(face[1].x, face[1].y, 7);
    rhythm_manager();
    break;
  case GAME_OVER:
  textAlign(CENTER);
    background(0, 40, 100);
    fill(0,75,50);
  text(score, width/2, height/4);
    gameOverTimer++;
    if (gameOverTimer>GAME_OVER_TIME) {
      GAMESTATE = PLAYING;
      gameOverTimer = 0;
      score = 0;
    }
    break;
  }
}

void move() {
  vx=0;
  vy=0;

  if (keys[0][0] && y>5) {
    vy = -10;
  }
  if (keys[0][1]&& y<height-5) {
    vy = 10;
  }
  if (keys[1][0]&&x>5) {
    vx = -10;
  }
  if (keys[1][1]&&x<width-5) {
    vx = 10;
  }
}

void keyPressed() {
  if (key=='w'||keyCode==UP)
    keys[0][0]=true;
  if (key=='s'||keyCode==DOWN)
    keys[0][1]=true;
  if (key=='a'||keyCode==LEFT)
    keys[1][0]=true;
  if (key=='d'||keyCode==RIGHT)
    keys[1][1]=true;
  if (key=='p'&&current_size<MAX_SIZE)
    plonk();
}

void keyReleased() {
  if (key=='w'||keyCode==UP)
    keys[0][0]=false;
  if (key=='s'||keyCode==DOWN)
    keys[0][1]=false;
  if (key=='a'||keyCode==LEFT)
    keys[1][0]=false;
  if (key=='d'||keyCode==RIGHT)
    keys[1][1]=false;
}

float getGirth(int pos) {
  return 10+current_size/(pos+1);
}

void manage_fruits() {
  if (millis()%1000>2&&random(0, 1)>0.90 && fruitPool.size()>0) {
    Fruit fruit = fruitPool.get(fruitPool.size()-1);
    fruit.place();
    activeFruits.add(fruit);
    fruitPool.remove(fruitPool.size()-1);
  }

  for (int i=0; i<activeFruits.size(); i++) {
    Fruit fruit = activeFruits.get(i);
    
    if (new PVector(fruit.x, fruit.y).dist(new PVector(x, y))<fruit.size+5) {
      play_random_lead_note();
      current_size+=fruit.points;
      score+=fruit.points;
      activeFruits.remove(i);
      i--;
      fruitPool.add(fruit);
    } else {
      fill(fruitColors[fruit.points]);
      circle(fruit.x, fruit.y, fruit.size);
      fill(120,100,70);
      ellipse(fruit.x+fruit.size/4, fruit.y-fruit.size/2, fruit.points*4,fruit.points*2);
      ellipse(fruit.x-fruit.size/4, fruit.y-fruit.size/2, fruit.points*4,fruit.points*2);
    }
  }
}

void calculate_collisions_with_fruits(int i){
  
        for (Fruit fruit : activeFruits) {
    PVector segPos = segments[i].getPos();
    PVector fruitPos = new PVector(fruit.x, fruit.y);

    float minDist = fruit.size/2 + getGirth(i)/2;
    float actualDist = PVector.dist(segPos, fruitPos);

    if (actualDist < minDist) {
        // Vector desde fruta hasta segmento
        PVector pushDir = PVector.sub(segPos, fruitPos);
        pushDir.normalize();
        pushDir.mult(minDist);

        // Recolocar segmento justo fuera del borde
        segPos.set(PVector.add(fruitPos, pushDir));

        // Actualizar la posición real del segmento
        segments[i].posX = segPos.x;
        segments[i].posY = segPos.y;
    }
}
  }
  

void game_over() {
  GAMESTATE = GAME_OVER;
  current_size=20;
  x=width/2;
  y=height/2;
}

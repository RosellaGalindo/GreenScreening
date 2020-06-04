import java.util.List;
import java.util.Arrays;



class CustomShape {
  
  Body       body;
  Polygon2D  toxiPoly;
  
  float oldBallPosX, oldBallPosY;
  
  color col;
  color col1, col2, col3, col4, col5, col6, col7;
  // Radius
  float r;
  
  // Class and its variables
  CustomShape(float x, float y, float r, BodyType type) {
    // Declare 'Float r' value
    this.r = r;
    
    // Call 'makeBody' function to declare x, y and type.
    makeBody(x, y, type);   
    
    // col calls 'getRandomColor()' but it can also store a specific colour.
    col = getRandomColor();     ////////////////////////////////////////////////////////
    //col = 0;
    col1 = color(255, 90, 90);
    col2 = color(255, 150, 90);
    col3 = color(255, 255, 90);
    col4 = color(90, 255, 90);
    col5 = color(90, 90, 255);
    col6 = color(255, 90, 255);
    col7 = color(255, 255, 255);
  }
  

  // 'makeBody' function
  void makeBody(float x, float y, BodyType type){
    BodyDef bd = new BodyDef();
    bd.type = type; // ??? Why not Dynamic?
    //bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    body = box2d.createBody(bd);
    
    // More bouncy and slow
    //body.setLinearVelocity(new Vec2(random(-10, 10), random(-2, 10))); /////////////
    //body.setLinearVelocity(new Vec2(random(-20, 20), random(-1, 10))); /////////////

    // Original settings
    //body.setLinearVelocity(new Vec2(random(-8, 8), random(2, 8))); /////////////    
    
    // No much gravity, shapes floating
    body.setLinearVelocity(new Vec2(random(-15, 15), random(2, 15))); /////////////
    
    // Original Angular Velocity
    //body.setAngularVelocity(random(-5, 5));
    body.setAngularVelocity(random(-15, 15));

//    if (r == -1){
//      PolygonShape sd = new PolygonShape();
//      toxiPoly = new Circle(random(5, 20)).toPolygon2D(int(random(3, 6)));
//      Vec2[] vertices = new Vec2[toxiPoly.getNumPoints()];

        // To generate vertex
//      for (int i = 0; i < vertices.length; i++){
//        Vec2D v = toxiPoly.vertices.get(i);
//        vertices[i] = box2d.vectorPixelsToWorld(new Vec2(v.x, v.y));
//      }
  
//      // Define a fixture (THE GLUE THAT ATTACHES BODY AND SHAPE)
//      sd.set(vertices, vertices.length);
//      // Creates the Fixture and attaches the shape with a density of 1
//      body.createFixture(sd, 1);
//    }

//    else {
      CircleShape cs = new CircleShape();
      cs.m_radius = box2d.scalarPixelsToWorld(r);
      
    // Define a fixture (THE GLUE THAT ATTACHES BODY AND SHAPE)
    // In here we can set: Density, friction and restitution
      FixtureDef fd = new FixtureDef();
      fd.shape = cs;
      //fd.density = 1;
      fd.density = 5;
      //fd.friction = 0.01;
      fd.friction = 0.001;
      // For Gravity / Bouncy
      ///fd.restitution = 0.3; 
      fd.restitution = 0.99;  
  
      body.createFixture(fd);
//    }
  }


  // Move shapes outside a person's polygon
  void update() {
    Vec2 posScreen = box2d.getBodyPixelCoord(body);
    Vec2D toxiScreen = new Vec2D(posScreen.x, posScreen.y);
    boolean inBody = poly.containsPoint(toxiScreen);
    if (inBody) {
      Vec2D closestPoint = toxiScreen;
      float closestDistance = 9999999;
      for (Vec2D v : poly.vertices) {
        float distance = v.distanceTo(toxiScreen);
        if (distance < closestDistance) {
          closestDistance = distance;
          closestPoint = v;
        }
      }
      Vec2 contourPos = new Vec2(closestPoint.x, closestPoint.y);
      Vec2 posWorld = box2d.coordPixelsToWorld(contourPos);
      
      float angle = body.getAngle();
      body.setTransform(posWorld, angle);
    }
  }


  // Display the customShape
  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    pushMatrix();
    translate(pos.x, pos.y);
    if (pos.x >= oldBallPosX) {
      ball.rotateBy(radians(((pos.y-oldBallPosY)*0.6)), radians(((pos.x-oldBallPosX)*0.3)), 0);
      //ball.rotateBy(0, radians(0.6f), 0);
    }
    else {
      ball.rotateBy(radians(((pos.y-oldBallPosY)*0.6)), radians(((pos.x-oldBallPosX)*0.3)), 0);
      ball.rotateBy(0, radians(-0.6f), 0);
    }
    
    noStroke();
    //fill(col);

//    if (r == -1) {
//      float a = body.getAngle();
//      rotate(-a); 
//      gfx.polygon2D(toxiPoly);
//    } 
//    else {

      ball.draw();
      
  
      //ellipse(0, 0, r*2, r*2);
      //rect(0,0, r*2, r*2);
      //ellipse(0, 0, r*5, r*5);  
      // If the value of r increases, the shapes become bigger and cover the silhouettes
//    }

    popMatrix();
    
    oldBallPosY = pos.y;
    oldBallPosX = pos.x;
  }


  // If the shape moves off-screen, destroy the box2d body
  boolean done() {
    Vec2 posScreen = box2d.getBodyPixelCoord(body);
    boolean offscreen = posScreen.y > height;
    if (offscreen) {
      box2d.destroyBody(body);
      return true;
    }
    return false;
  }
}

/*-----------------------------------------------------------------------
 - The Green Screening Workshop 
   (Split Britches & QMUL)
  
 - Project by Rosella Galindo and David Smith
 - Based on the SimpleOpenNI and Box2D libraries
 - Adapted from CAN Kinect Physics (https://github.com/msp/CANKinectPhysics) 
   by Amnon Owed and Arindam Sen

   KEYBOARD CONTROL
   1 - Still photo
 ------------------------------------------------------------------------*/

 

import processing.opengl.*; 
import SimpleOpenNI.*;
import blobDetection.*;
import toxi.geom.*;
import toxi.processing.*;
import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;

SimpleOpenNI kinect;
BlobDetection blob_detection;
ToxiclibsSupport gfx;
Box2DProcessing box2d;

PolygonBlob poly;  
int kinectWidth = 640;
int kinectHeight = 480;
int nthFrame = 480;
float reScale;
PImage cam, blobs, flipped;
color bg_color, blob_color;
color[] color_palette;
ArrayList<CustomShape> polygons; // Array containing the falling figures


// Three color palettes (artifact from me storing many interesting color palettes as strings in an external data file ;-)
String[] palettes = {
  "-1117720,-13683658,-8410437,-9998215,-1849945,-5517090,-4250587,-14178341,-5804972,-3498634", 
  "-67879,-9633503,-8858441,-144382,-4996094,-16604779,-588031", 
  "-1978728,-724510,-15131349,-13932461,-4741770,-9232823,-3195858,-8989771,-2850983,-10314372"
};
 
void setup() {
  //size(displayWidth, displayHeight, OPENGL);
  fullScreen(OPENGL);
  
  kinect = new SimpleOpenNI(this);
  if (!kinect.enableDepth() || !kinect.enableUser()) { 
    println("Your kinect might not be connected!"); 
    exit();
    return;
  }
  else {
    kinect.setMirror(true);
    reScale = (float) width / kinectWidth;
    cam = createImage(640, 480, RGB);
    blobs = createImage(kinectWidth / 3, kinectHeight / 3, RGB);
    flipped = createImage(blobs.width,blobs.height,RGB); // create a new image to store flipped info with the same dimensions
    blob_detection = new BlobDetection(blobs.width, blobs.height);
    blob_detection.setThreshold(0.3);
    gfx = new ToxiclibsSupport(this);
    
    // set up colors
    bg_color = color(252, 244, 209);
    blob_color = color(124, 40, 12);
    String[] palette_strings = split(palettes[int(random(palettes.length))], ",");
    color_palette = new color[palette_strings.length];
    for (int i = 0; i < palette_strings.length; i++) {
      color_palette[i] = int(palette_strings[i]);
    }

    // Create world, set gravity
    box2d = new Box2DProcessing(this);
    box2d.createWorld();
    box2d.setGravity(0, -60); 
    polygons = new ArrayList<CustomShape>();
    setRandomColors();
  }


}


void drawString(float x, float size, int cards) { 
  float gap = kinectHeight / cards;
  CustomShape s1 = new CustomShape(x, -40, size, BodyType.DYNAMIC);
  polygons.add(s1);
  
  CustomShape last_shape = s1;
  CustomShape next_shape;
  for (int i = 0; i < cards; i++){
    float y = -20 + gap * (i+1);
    next_shape = new CustomShape(x, -20 + gap * (i+1), size, BodyType.DYNAMIC);
    DistanceJointDef jd = new DistanceJointDef();
    Vec2 c1 = last_shape.body.getWorldCenter();
    Vec2 c2 = next_shape.body.getWorldCenter();
    c1.y = c1.y + size / 5;
    c2.y = c2.y - size / 5;
    jd.initialize(last_shape.body, next_shape.body, c1, c2);
    jd.length = box2d.scalarPixelsToWorld(gap - 1);
    box2d.createJoint(jd);
    polygons.add(next_shape);
    last_shape = next_shape;
  }
}

 
void draw() {
  background(bg_color);
  kinect.update();
  cam = kinect.userImage();
  cam.loadPixels();
  color black = color(0, 0, 0);
  for (int i = 0; i < cam.pixels.length; i++){ 
    color pix = cam.pixels[i];
    int blue = pix & 0xFF;
    if (blue == ((pix >> 8) & 0xff) && blue == ((pix >> 16) & 0xff)){
      cam.pixels[i] = black;
    }
  }
  
  
  cam.updatePixels();
  
  // Copy image into smaller blob image
  blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
  blobs.filter(BLUR, 1);
  //flip image
  for(int i = 0 ; i < flipped.pixels.length; i++){       
    int srcX = i % flipped.width;
    int dstX = flipped.width - srcX - 1;
    int y    = i / flipped.width;
    flipped.pixels[y * flipped.width + dstX] = blobs.pixels[i]; 
  }
  blob_detection.computeBlobs(flipped.pixels);
  
  // create a Polygon, attach the Polygon to a Body, destroy Polygon/Body
  poly = new PolygonBlob();
  poly.createPolygon();
  poly.createBody();
  updateAndDrawBox2D();
  poly.destroyBody();
  
  if (frameCount % nthFrame == 0) {
     setRandomColors();
   }
}
 
 
void updateAndDrawBox2D() {
  // If frameRate is sufficient, add a polygon and a circle with a random radius  
  if (frameRate > 30) {
    CustomShape shape = new CustomShape(kinectWidth/2, -50, random(1.5, 20), BodyType.DYNAMIC);
    polygons.add(shape);
  }
  box2d.step(); // take one step in the box21d physics world
  translate(0, (height - kinectHeight * reScale) / 2); // center and reScale from Kinect to custom dimensions 
  scale(reScale);
  noStroke();
  fill(blob_color);
  gfx.polygon2D(poly); // Display the person's polygon  
  
  // For polygons and circles
  for (int i = polygons.size()-1; i >= 0; i--) {
    CustomShape cs = polygons.get(i);    
    if (cs.done()) {
      polygons.remove(i);
    } 
    else {
      cs.update();
      cs.display();
    }
  }
}

// Sets the colors 
void setRandomColors() {    
    for (CustomShape cs: polygons) { cs.col = getRandomColor(); }
}
 
// Returns a random color from the palette
color getRandomColor() {
  return color_palette[int(random(1, color_palette.length))];
}

// Save screen capture
void keyPressed() {
  if (keyCode == '1') { 
    saveFrame("line-######.jpg");
    //saveFrame(); // Save the current frame as a .tif image, in the root folder of the sketch.
  }

}

/*-----------------------------------------------------------------------
 - The Green Screening Workshop 
   (Split Britches & QMUL)
  
 - Project by Gideon Raeburn
 - Based on the Open Kinect for Processing and Box2D libraries
 - Inspired on CAN Kinect Physics (https://github.com/msp/CANKinectPhysics) 
   by Amnon Owed and Arindam Sen
 - Big thanks to Rosella Galindo and David Smith for previous iterations

   KEYBOARD CONTROL
   1 - Still photo
   3 - Hide/Show GUI
 ------------------------------------------------------------------------*/



import processing.opengl.*; 
import org.openkinect.processing.*;
import blobDetection.*;
import toxi.geom.*;
import toxi.processing.*;
import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import controlP5.*;

// 3D shape library for beach ball
import shapes3d.utils.*;
import shapes3d.animation.*;
import shapes3d.*;

Ellipsoid ball;

Kinect kinect;
ControlP5 cp5;
BlobDetection blob_detection;
ToxiclibsSupport gfx;
Box2DProcessing box2d;

PolygonBlob poly;  
int kinectWidth = 640;
int kinectHeight = 480;
int nthFrame = 480;
float reScale;
PImage cam, img, blobs, flipped;
color bg_color, blob_color;
color[] color_palette;
ArrayList<CustomShape> polygons; // Array containing the falling figures

float minThresh = 400;
float maxThresh = 800;
boolean show_gui = false;

// Three color palettes (artifact from me storing many interesting color palettes as strings in an external data file ;-)
String[] palettes = {
  "-1117720,-13683658,-8410437,-9998215,-1849945,-5517090,-4250587,-14178341,-5804972,-3498634", 
  "-67879,-9633503,-8858441,-144382,-4996094,-16604779,-588031", 
  "-1978728,-724510,-15131349,-13932461,-4741770,-9232823,-3195858,-8989771,-2850983,-10314372"
};

void setup() {
  // fullscreen
  fullScreen(OPENGL);
  //size(displayWidth, displayHeight, OPENGL);

  kinect = new Kinect(this);

  kinect.initDepth();
  
  // create beachball
  ball = new Ellipsoid(this, 16, 16);
  ball.setTexture("ball.jpg");
  ball.setRadius(50);
  /*ball.moveTo(new PVector(0, 0, 0));
  ball.strokeWeight(1.0f);
  ball.stroke(color(255, 255, 0));
  ball.moveTo(20, 40, -80);*/
  ball.tag = "Beachball";
  ball.drawMode(shapes3d.Shape3D.TEXTURE);

  //kinect.enableMirror(true);
  reScale = (float) width / kinectWidth;
  cam = createImage(640, 480, RGB);
  blobs = createImage(kinectWidth / 3, kinectHeight / 3, RGB);
  flipped = createImage(blobs.width, blobs.height, RGB); // create a new image to store flipped info with the same dimensions
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

  // Create world, SET GRAVITY HERE!!
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -50); 
  polygons = new ArrayList<CustomShape>();
  setRandomColors();
  
  // Depth sliders for max and min depths
  cp5 = new ControlP5(this);
  cp5.addSlider("minThresh").setPosition(20,20).setRange(0.0f,2048.0f);
  cp5.addSlider("maxThresh").setPosition(20,40).setRange(0.0f,2048.0f);
}

void draw() {
  background(bg_color);
  //kinect.update();
  img = kinect.getDepthImage();
  int[] depth = kinect.getRawDepth();
  
  // only show kinect image within set depth range
  for (int x = 0; x < kinect.width; x++) {
      for (int y = 0; y < kinect.height; y++) {
        int pixel = x + y * kinect.width;
        int d = depth[pixel];
        
        if ((d > minThresh) && (d < maxThresh)) {
          cam.pixels[pixel] = img.pixels[pixel];
        }
        else cam.pixels[pixel] = color(0, 0, 0);
        }     
    }
    
    cam.updatePixels();

  // Copy image into smaller blob image
  blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
  blobs.filter(BLUR, 1);
  //flip image
  for (int i = 0; i < flipped.pixels.length; i++) {       
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
  pushMatrix();
  // Add a single beachball object of size 50 if none on the screen   
  if (polygons.size() == 0) {
    CustomShape shape = new CustomShape(kinectWidth/2, -50, 50, BodyType.DYNAMIC);
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
    } else {
      cs.update();
      cs.display();
    }
  }
  popMatrix();
}

// Sets the colors 
void setRandomColors() {    
  for (CustomShape cs : polygons) { 
    cs.col = getRandomColor();
  }
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
  else if (keyCode == '3') {
    show_gui = !show_gui;
    cp5.setVisible(show_gui);
  }
}

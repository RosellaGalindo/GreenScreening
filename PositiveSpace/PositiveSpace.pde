/*-----------------------------------------------------------------------
 - The Green Screening Workshop 
   (Split Britches & QMUL)
  
 - Project by Gideon Raeburn
 - Based on the SimpleOpenNI library
 - Adapted from CAN Kinect Flow (https://github.com/msp/CANKinectPhysics) 
   by Amnon Owed
   
   KEYBOARD CONTROL
   1 - Still photo
------------------------------------------------------------------------*/



// import libraries
import processing.opengl.*; // opengl
import SimpleOpenNI.*; // kinect
import blobDetection.*; // blobs

// this is a regular java import so we can use and extend the polygon class (see PolygonBlob)
import java.awt.Polygon;

// declare SimpleOpenNI object
SimpleOpenNI kinect;
// declare BlobDetection object
BlobDetection theBlobDetection;
// declare custom PolygonBlob object (see class for more info)
PolygonBlob poly = new PolygonBlob();

int[] user_mapping;
// PImage to hold incoming imagery and smaller one for blob detection
PImage depth_image, blobs, composition;

// the kinect's dimensions to be used later on for calculations
int kinectWidth = 640;
int kinectHeight = 480;
// to center and rescale from 640x480 to higher custom resolutions
float reScale;

// background color
color bgColor;
// three color palettes (3rd palette is the black background which can be commented out if desired)
String[] palettes = {
  //"-1117720,-13683658,-8410437,-9998215,-1849945,-5517090,-4250587,-14178341,-5804972,-3498634"//, 
  //"-67879,-9633503,-8858441,-144382,-4996094,-16604779,-588031"//, 
  "-16711663,-13888933,-9029017,-5213092,-1787063,-11375744,-2167516,-15713402,-5389468,-2064585"
};

// an array called flow of 2250 Particle objects (see Particle class)
Particle[] flow = new Particle[2250];
// global variables to influence the movement of all particles
float globalX, globalY;

void setup() {
  // fullscreen
  fullScreen(OPENGL);
  // it's possible to customize this, for example 1920x1080
  //size(1280, 720, OPENGL);
  // initialize SimpleOpenNI object
  
  kinect = new SimpleOpenNI(this);
  
  if (kinect.isInit() == false) { 
    // if context.enableScene() returns false
    // then the Kinect is not working correctly
    // make sure the green light is blinking
    println("Kinect not connected!"); 
    exit();
    return;
  }
    // mirror the image to be more intuitive
    kinect.setMirror(true);
    kinect.enableDepth();
    kinect.enableUser();
    
    // calculate the reScale value
    // currently it's rescaled to fill the complete width (cuts of top-bottom)
    // it's also possible to fill the complete height (leaves empty sides)
    reScale = (float) width / kinectWidth;
    
    // create a smaller blob image for speed and efficiency
    blobs = createImage(kinectWidth/3, kinectHeight/3, RGB);
    // initialize blob detection object to the blob image dimensions
    theBlobDetection = new BlobDetection(blobs.width, blobs.height);
    theBlobDetection.setThreshold(0.2);
    setupFlowfield();
    
    composition = new PImage(kinect.depthWidth(), kinect.depthHeight(), ARGB);
    noStroke();
    smooth(); 
}

void draw() {
  // fading background
  noStroke();
  fill(bgColor, 65);
  rect(0, 0, width, height);
  
  // update the SimpleOpenNI object
  kinect.update();
  
  // put the image into a PImage
  //depth_image = kinect.depthImage();
  user_mapping = kinect.userMap();
  
  composition.loadPixels();
  for (int i =0; i < user_mapping.length; i++) {
    if (user_mapping[i] != 0) {
      composition.pixels[i] = color(255);
    }
    else composition.pixels[i] = color(0);
  }
  composition.updatePixels();
  
  // copy the image into the smaller blob image
  blobs.copy(composition, 0, 0, composition.width, composition.height, 0, 0, blobs.width, blobs.height);
  // blur the blob image
  blobs.filter(BLUR);
  // detect the blobs
  theBlobDetection.computeBlobs(blobs.pixels);
  // clear the polygon (original functionality)
  poly.reset();
  // create the polygon from the blobs (custom functionality, see class)
  poly.createPolygon();
  drawFlowfield();
}

void setupFlowfield() {
  // set stroke weight (for particle display) to 2.5
  strokeWeight(2.5);
  // initialize all particles in the flow
  for(int i=0; i<flow.length; i++) {
    flow[i] = new Particle(i/10000.0);
  }
  // set all colors randomly now
  setRandomColors(1);
}

void drawFlowfield() {
  // center and reScale from Kinect to custom dimensions
  translate(0, (height-kinectHeight*reScale)/2);
  scale(reScale);
  // set global variables that influence the particle flow's movement
  globalX = noise(frameCount * 0.01) * width/2 + width/4;
  globalY = noise(frameCount * 0.005 + 5) * height;
  // update and display all particles in the flow
  for (Particle p : flow) {
    p.updateAndDisplay();
  }
  // set the colors randomly every 240th frame
  setRandomColors(240);
}

// sets the colors every nth frame
void setRandomColors(int nthFrame) {
  if (frameCount % nthFrame == 0) {
    // turn a palette into a series of strings
    String[] paletteStrings = split(palettes[int(random(palettes.length))], ",");
    // turn strings into colors
    color[] colorPalette = new color[paletteStrings.length];
    for (int i=0; i<paletteStrings.length; i++) {
      colorPalette[i] = int(paletteStrings[i]);
    }
    // set background color to first color from palette
    bgColor = colorPalette[0];
    // set all particle colors randomly to color from palette (excluding first aka background color)
    for (int i=0; i<flow.length; i++) {
      flow[i].col = colorPalette[int(random(1, colorPalette.length))];
    }
  }
}


void keyPressed() {
  if (keyCode == '1') { 
    saveFrame("line-######.jpg");
    //saveFrame(); // Save the current frame as a .tif image, in the root folder of the sketch.
  }
}

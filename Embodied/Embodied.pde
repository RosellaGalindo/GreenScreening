/*-----------------------------------------------------------------------
 - The Green Screening Workshop 
   (Split Britches & QMUL)
  
 - Project by Rosella Galindo & David Smith
 - Based on the Open Kinect libraries
 - Adapted from Kinect Point Cloud example - Kinect_v1 (https://github.com/shiffman/OpenKinect-for-Processing) 
   by Daniel Shiffman

   KEYBOARD CONTROL
   1 - Still photo
   3 - Hide/Show GUI
 ------------------------------------------------------------------------*/
 
 

import org.openkinect.freenect.*; 
import org.openkinect.processing.*;
import controlP5.*;

Kinect kinect;
ControlP5 cp5;

PGraphics pg;
boolean show_gui = false;
boolean flip = false;
float rotation = 0;
float angle = 0;
float transp;
int skip = 4; // How detailed to draw point cloud
float[] depth_lookUp = new float[2048]; // Lookup table for Raw values (0 to 2048)
float factor = 200;
float maxZ = 4.0;
float minZ = 0.0;
float point_size = 1.0f;


void setup() 
{
  //size(displayWidth, displayHeight, OPENGL);
  fullScreen(OPENGL);
  
  kinect = new Kinect(this);
  kinect.initDepth();

  for (int i = 0; i < depth_lookUp.length; i++) {
    depth_lookUp[i] = rawDepthToMeters(i);
  }

  cp5 = new ControlP5(this);
  cp5.addSlider("minZ").setPosition(20,20).setRange(0.0f,5.0f);
  cp5.addSlider("maxZ").setPosition(20,40).setRange(0.0f,5.0f);
  cp5.addSlider("rotation").setPosition(20,60).setRange(0.0f,0.1f);
  cp5.addSlider("transp").setPosition(20,80).setRange(0.0f, 125.0f);
  cp5.addSlider("skip").setPosition(20,100).setRange(1, 40);
  cp5.addSlider("pointSize").setPosition(20,120).setRange(1, 10);
  cp5.addToggle("mirror").setPosition(20,140).setSize(50,20).setValue(flip).setMode(ControlP5.SWITCH);
  
  pg = createGraphics(width, height, P3D);
}


void draw() 
{
  int[] depth = kinect.getRawDepth();   // Get the raw depth as array of integers

  pg.beginDraw();
  darken(pg);
  pg.strokeWeight(point_size);
  pg.pushMatrix();
  pg.scale(flip ? -1 : 1, 1);
  pg.translate( (flip ? -1 : 1) * width / 2 , height / 2, -100);
  pg.rotateY(angle);

  for (int x = skip; x < kinect.width - skip; x += skip) {
    for (int y = skip; y < kinect.height - skip; y += skip) {
      int offset = x + y*kinect.width;
      int rawDepth = depth[offset];
      PVector pv = depthToWorld(x - skip, y - skip, rawDepth);
      PVector v = depthToWorld(x, y, rawDepth);
      PVector nv = depthToWorld(x + skip, y + skip, rawDepth);
      if (v.z > minZ && v.z < maxZ) {
        pg.stroke(255);
        pg.pushMatrix();
        pg.translate(v.x*factor*2, v.y*factor*2, factor - v.z*factor);    
        pg.point(0, 0);
        pg.popMatrix();
      }
    }
  }
  pg.popMatrix();
  pg.noStroke();
  pg.endDraw();
  image(pg, 0, 0);
  angle += rotation;
}


// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

void darken(PGraphics pg) { 
  background(0);
 
  pg.loadPixels();
  for (int y = 0; y < pg.height; y++) {
    for (int x = 0; x < pg.width; x++) {
      int loc = x + y * pg.width;
      float r = red(pg.pixels[loc]);
      float g = green(pg.pixels[loc]);
      float b = blue(pg.pixels[loc]);
      pg.pixels[loc] = color(r - transp, g - transp, b - transp, 35);
    }
  }
  pg.updatePixels();  
}


PVector depthToWorld(int x, int y, int depthValue) {
  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;
  PVector result = new PVector();
  double depth =  depth_lookUp[depthValue];
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}


// Save screen capture
void keyPressed() {
  if (keyCode == '1') { 
    //saveFrame();
    saveFrame("line-######.jpg");
  }
  else if (keyCode == '3') {
    show_gui = !show_gui;
    cp5.setVisible(show_gui);
  }
}  

void mirror(boolean the_flag) {
  flip = the_flag;
}

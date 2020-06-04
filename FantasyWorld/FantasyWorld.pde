/*-----------------------------------------------------------------------
 - The Green Screening Workshop 
   (Split Britches & QMUL)
   
 - Project by Gideon Raeburn
 - Based on the Open Kinect for Processing library (https://github.com/shiffman/OpenKinect-for-Processing
 - Based on the VideoExport for Processing library (https://github.com/hamoid/video_export_processing)
 - Big thanks to Rosella Galindo and David Smith for previous iterations

   KinectV1 640x480. Point cloud to draw pink 3D image within certain depth.
   Depth values 0 to 2048.
   
   KEYBOARD CONTROL
   1 - Still photo
   2 - Load background image
   3 - Hide/Show GUI
   R/r - Record video
 ------------------------------------------------------------------------*/
 
 
 
// kinect library
import org.openkinect.processing.*;
// video export library
import com.hamoid.*;
// gui library
import controlP5.*;

Kinect kinect;
ControlP5 cp5;

int kinectWidth = 640;
int kinectHeight = 480;

// variables for taking still photo
int fade_speed;
long time;
int photo = 0;
int al = 255;

// default depth range
float minThresh = 400;
float maxThresh = 1000;
int horReg = 40; 
int vertReg = 14;
int Vert = 29;

// scale kinect image to fit screen
float reScale;

PImage img, rgb, bgImage;

// video export
VideoExport videoExport;
boolean recording = false;
int count = 0;
// give a unique video file name
final String AZ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
String fileNo;

// gui variables
Textlabel Label1;
Textlabel Label2;
Textlabel Label3;
Knob Knob1;
boolean show_gui = false;

void setup() {
  
  // full screen
  fullScreen(P2D);
  //size(displayWidth, displayHeight, P2D);
  kinect = new Kinect(this);
  
  // kinect.enableMirror(true);
  
  kinect.initDepth();
  kinect.initVideo();
  
  // scale factor based on screen size
  reScale = (float) width/kinect.width;
  
  scale(reScale);
  background(0);
  
  // Don't need initDevice() Kinect V1
  
  img = createImage(kinect.width, kinect.height, ARGB);
  
  // still photo flash fade speed
  fade_speed = 15;
  
  // video export
  videoExport = new VideoExport(this);
  videoExport.setDebugging(false);
  fileNo = ""+AZ.charAt((int)random(26))+AZ.charAt((int)random(26))+AZ.charAt((int)random(26));
 
  // gui setup
  cp5 = new ControlP5(this);
  cp5.addSlider("minThresh").setPosition(20,20).setRange(0.0f,2048.0f);
  cp5.addSlider("maxThresh").setPosition(20,40).setRange(0.0f,2048.0f);
  cp5.addSlider("horReg").setPosition(20,60).setRange(1, 50);
  cp5.addSlider("vertReg").setPosition(20,80).setRange(1,50);
  cp5.addSlider("Vert").setPosition(20,100).setRange(1,50);
  Knob1 = cp5.addKnob("").setPosition(20,120).setSize(25,25).setLabelVisible(false).setShowAngleRange(false).setColorBackground(color(255,0,0)).setColorForeground(color(255,0,0)).removeBehavior().setVisible(false);
  Label1 = cp5.addTextlabel("Label1").setText("1").setPosition(width/2,height/2).setColor(255).setFont(createFont("Arial",130)).setVisible(false);
  Label2 = cp5.addTextlabel("Label2").setText("2").setPosition(width/2,height/2).setColor(255).setFont(createFont("Arial",130)).setVisible(false);
  Label3 = cp5.addTextlabel("Label3").setText("3").setPosition(width/2,height/2).setColor(255).setFont(createFont("Arial",130)).setVisible(false);
}

void draw() {
  // show BG image
  if (bgImage != null) {
    image(bgImage, 0, 0, width, height);
  }  
  
  rgb = kinect.getVideoImage();
  
  //get raw depth as integer array
  int[] depth = kinect.getRawDepth();
  
    for (int x = 0; x < kinect.width; x++) {
      for (int y = 0; y < kinect.height; y++) {
        // pixels stored in single array so find pixel index
        int pixel = x + y * kinect.width;
        int d = depth[pixel];
        
        // show user if within depth correcting for depth and rgb camera mis-registration
        if ((d > minThresh) && (d < maxThresh) && (pixel < (kinect.width*kinect.height-(Vert)*640 +x/(d/horReg)+(640*(y/vertReg))))) {
          img.pixels[pixel] = rgb.pixels[pixel+Vert*640-x/(d/horReg)-(640*(y/vertReg))];
        }
        // black BG if no image
        else if (bgImage == null) {
          img.pixels[pixel] = color(0);
        }
        // BG image
        else {
          color c = img.pixels[pixel];
          img.pixels[pixel] = color(75, 75, 75, alpha(c) - fade_speed);
        }
          
      }
    }
    
    // show partcipant and BG
    img.updatePixels();
    pushMatrix();
    scale(reScale);
    scale(-1,1);
    image(img, -kinect.width, 0);
    popMatrix();

    // countdown to take still photo and video when buttons pressed
    pushMatrix();
    scale(reScale);
    
    // snapshot
    if ((millis() < (time+1000)) && (photo == 1)) {
      Label3.setVisible(true);
    }
    else if ((millis() >= (time + 1000)) && (millis() < (time+2000)) && (photo == 1)) {
      Label3.setVisible(false);
      Label2.setVisible(true);
    }
    else if ((millis() >= (time + 2000)) && (millis() < (time+3000)) && (photo == 1)) {
      Label2.setVisible(false);
      Label1.setVisible(true);
    }
    else if ((millis() >= (time + 3000)) && (photo == 1)) {
      Label1.setVisible(false);
      saveFrame("line-######.jpg");
      photo = 2;
    }
    else if ((millis() > (time + 3000)) && (millis() < (time+4000)) && (photo == 2)) {
      fill(255, al);
      rect(0, 0, kinect.width, kinect.height);
      al = al - fade_speed;
    }
    else photo = 0;
    
    // video
    if (recording) {
      videoExport.saveFrame();
    }
    popMatrix();
}

// buttons to record stills, video and hide gui
void keyPressed() {
  if (keyCode == '1') {
    photo = 1;
    time  = millis();
    al = 255;
  }
  else if (keyCode == '2') {
    selectInput( "Select an image", "imageChosen" );
  }
  else if (keyCode == '3') {
    show_gui = !show_gui;

    cp5.setVisible(show_gui);
  }
  else if (key == 'r' || key == 'R') {
    recording = !recording;
    if (recording == true) {
      count++;
      Knob1.setVisible(true);
      videoExport.forgetFfmpegPath();  /// Avoids crashing in Rosella's mac
      videoExport.setMovieFileName(fileNo+count + ".mp4");
      videoExport.startMovie();

    }
    else if (recording == false) {
      Knob1.setVisible(false);
      videoExport.endMovie();
  
    }
  }
}  
 
// load a BG image
void imageChosen(File f) {
  if(f.exists()){
     bgImage = loadImage(f.getAbsolutePath()); 
  }
}
   

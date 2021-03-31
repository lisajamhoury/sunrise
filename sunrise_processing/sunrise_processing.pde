PImage myTexture;
PShader myShader;
PGraphics myGraphics;

boolean DEBUG = false;
boolean RECORD = true;

// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)

// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube

float previousTime = 0.0;

boolean mouseDragged = false;

PVector lastMousePosition;
float mouseClickState = 0.0;

void setup() {
  // size(1728, 135, P2D);
  //size(3456, 270, P2D);
   size(6912, 540, P2D);

  frameRate(30);


  myTexture = createImage(256,256,ARGB);
  myGraphics = createGraphics(width, height);
  
  // Load the shader file from the "data" folder
  myShader = loadShader("sunrise_p3.glsl");
  
  // We assume the dimension of the window will not change over time, 
  // therefore we can pass its values in the setup() function  
  myShader.set("iResolution", float(width), float(height), 0.0);
  
  lastMousePosition = new PVector(float(mouseX),float(mouseY));
}


void draw() {
  
  // shader playback time (in seconds)
  float currentTime = millis()/1000.0;
  myShader.set("iTime", currentTime);
  
    // myShader.set("iChannel0", myTexture);

  
  // render time (in seconds)
  float timeDelta = currentTime - previousTime;
  previousTime = currentTime;
  myShader.set("iDeltaTime", timeDelta);
  
  // shader playback frame
  myShader.set("iFrame", frameCount);
  
  // mouse pixel coords. xy: current (if MLB down), zw: click
  if(mousePressed) { 
    lastMousePosition.set(float(mouseX),float(mouseY));
    mouseClickState = 1.0;
  } else {
    mouseClickState = 0.0;
  }

   //println("mouseX: "+ mouseX + " mouseY: " + mouseY);
  // myShader.set( "iMouse", lastMousePosition.x, lastMousePosition.y, mouseClickState, mouseClickState);
  myShader.set("iMouse", float(mouseX), float(mouseY), mouseClickState, mouseClickState);

  // Set the date
  // Note that iDate.y and iDate.z contain month-1 and day-1 respectively, 
  // while x does contain the year (see: https://www.shadertoy.com/view/ldKGRR)
  float timeInSeconds = hour()*3600 + minute()*60 + second();
  myShader.set("iDate", year(), month()-1, day()-1, timeInSeconds );  

  // This uniform is undocumented so I have no idea what the range is
  myShader.set("iFrameRate", frameRate);

  // Apply the specified shader to any geometry drawn from this point  
  shader(myShader);

  // // Draw the output of the shader onto a rectangle that covers the whole viewport.
  rect(0, 0, width, height);
  
  resetShader();
  


  if (DEBUG) {
  myGraphics.beginDraw();
  myGraphics.strokeWeight(2);
  myGraphics.stroke(255,0,0);
  myGraphics.line(width/2, 0, width/2, height); 
  myGraphics.endDraw();
  image(myGraphics, 0,0, width, height);
  }
  
    if (RECORD) {
    saveFrame("output/sr_####.png");
  }


  
}

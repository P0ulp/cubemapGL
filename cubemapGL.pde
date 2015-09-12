import peasy.*;
import java.nio.IntBuffer;

IntBuffer envMapTextureID;

PShader cubemapShaderReflection;
PShader cubemapShaderRefraction;
PeasyCam cam;
PImage tex;
PMatrix3D matShader;
PShape glass;
Boolean reflection = true;



void setup() {
  size(1024, 800, P3D);
  
  matShader = new PMatrix3D();
  tex =  loadImage("city.jpg");
 
  generateCubeMap();
  // Load cubemap shader.
  cubemapShaderReflection = loadShader("cubemapfragReflect.glsl", "cubemapvertReflect.glsl");
  cubemapShaderReflection.set("cubemap", 1);
  cubemapShaderRefraction = loadShader("cubemapfragRefract.glsl", "cubemapvertRefract.glsl");
  cubemapShaderRefraction.set("cubemap", 1);

  cam = new PeasyCam(this, width/2, height/2, 0, 180);
}

void draw() {


  background(0);
  pushMatrix();
  translate(width/2,height/2,0);
  scale(2000);
  noStroke();
  texturedCube(tex);
  popMatrix();
  
  hint(DISABLE_OPTIMIZED_STROKE);
  pushMatrix();
  translate(width/2,height/2,0);
  if(reflection){
    shader(cubemapShaderReflection);
    
    PGraphics3D g3 = (PGraphics3D)g;
    matShader = g3.modelviewInv.get();
    //matShader.transpose();
    matShader.print();
    cubemapShaderReflection.set("modelviewInv",matShader);
  }
  else{
    shader(cubemapShaderRefraction);
    PGraphics3D g3 = (PGraphics3D)g;
    matShader = g3.modelviewInv.get();
    matShader.transpose();

    cubemapShaderRefraction.set("modelviewInv",matShader);
  }
  box(60);
  resetShader();
  popMatrix();
  
  frame.setTitle(int(frameRate) + " fps");
}


void texturedCube(PImage tex) {
  beginShape(QUADS);
  texture(tex);

  // +Z "front" face

  vertex(-1, -1, 1, 1024, 1024);
  vertex( 1, -1, 1, 2048, 1024);
  vertex( 1, 1, 1, 2048, 2045);
  vertex(-1, 1, 1, 1024, 2045);

  // -Z "back" face
  vertex( 1, -1, -1, 3072, 1024);
  vertex(-1, -1, -1, 4095, 1024);
  vertex(-1, 1, -1, 4095, 2045);
  vertex( 1, 1, -1, 3072, 2045);

  // +Y "bottom" face
  vertex(-1, 1, 1, 1026, 2048);
  vertex( 1, 1, 1, 2044, 2048);
  vertex( 1, 1, -1, 2044, 3072);
  vertex(-1, 1, -1, 1026, 3072);

  // -Y "top" face
  vertex(-1, -1, -1, 1026, 0);
  vertex( 1, -1, -1, 2046, 0);
  vertex( 1, -1, 1, 2046, 1024);
  vertex(-1, -1, 1, 1026, 1024);

  // +X "right" face
  vertex( 1, -1, 1, 2048, 1024);
  vertex( 1, -1, -1, 3072, 1024 );
  vertex( 1, 1, -1, 3072, 2045);
  vertex( 1, 1, 1, 2048, 2045);

  // -X "left" face
  vertex(-1, -1, -1, 1, 1026);
  vertex(-1, -1, 1, 1024, 1026);
  vertex(-1, 1, 1, 1024, 2045);
  vertex(-1, 1, -1, 1, 2045);

  endShape();
}

void generateCubeMap(){
   PGL pgl = beginPGL();
  // create the OpenGL cubeMap
  envMapTextureID = IntBuffer.allocate(1);
  pgl.genTextures(1, envMapTextureID);
  pgl.activeTexture(PGL.TEXTURE1);
  pgl.enable(PGL.TEXTURE_CUBE_MAP);
  pgl.bindTexture(PGL.TEXTURE_CUBE_MAP, envMapTextureID.get(0));
  

  String[] textureNames = { 
    "posx.jpg", "negx.jpg", "posy.jpg", "negy.jpg", "posz.jpg", "negz.jpg"
  };
  PImage[] textures = new PImage[textureNames.length];
  for (int i=0; i<textures.length; i++) {
    textures[i] = loadImage("tex/"+textureNames[i]);
  }

  // put the textures in the cubeMap
  for (int i=0; i<textures.length; i++) {
    int w = textures[i].width;
    int h = textures[i].height;
    textures[i].loadPixels();
    int[] pix = textures[i].pixels;
    int[] rgbaPixels = new int[pix.length];
    for (int j = 0; j< pix.length; j++) {
      int pixel = pix[j];
      rgbaPixels[j] = 0xFF000000 | ((pixel & 0xFF) << 16) | ((pixel & 0xFF0000) >> 16) | (pixel & 0x0000FF00);
    }
    pgl.texImage2D(PGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, PGL.RGBA, w, h, 0, PGL.RGBA, PGL.UNSIGNED_BYTE, java.nio.IntBuffer.wrap(rgbaPixels));
  }
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_WRAP_S, PGL.CLAMP_TO_EDGE);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_WRAP_T, PGL.CLAMP_TO_EDGE);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_WRAP_R, PGL.CLAMP_TO_EDGE);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_MIN_FILTER, PGL.LINEAR);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_MAG_FILTER, PGL.LINEAR);
  endPGL();
}

void keyPressed() {
  if (key == ' ') {
      reflection = !reflection;
  } 
}

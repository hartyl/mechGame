// written by groverbuger for g3d
// september 2021
// MIT license

// this vertex shader is what projects 3d vertices in models onto your 2d screen
//noperspective varying vec2 texCoord;

attribute vec4 InstancePosition;
uniform lowp float[6] projectionArray;
uniform mat3 viewMatrix; // handled by the camera

uniform vec3 translation;
//uniform bool isCanvasEnabled; // detect when this model is being rendered to a canvas

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec3 worldPosition;
varying vec3 viewPosition;
varying vec4 screenPosition;
varying vec3 cameraForward;
// varying vec3 vertexNormal;
// varying vec4 vertexColor;
// uniform mat4 modelMatrix;      // models send their own model matrices when drawn

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
  // calculate the positions of the transformed coordinates on the screen
  // save each step of the process, as these are often useful when writing custom fragment shaders
  // worldPosition += vec4(vertexPosition.x,vertexPosition.y,vertexPosition.z,0);
  // float cosPitch = sin(cameraRight.z);
  // vec3 cameraUp = vec3(cameraRight.y*cosPitch,-cameraRight.x*cosPitch,-cos(cameraRight.z));
  // vec3 cameraForward = -cross(vec3(cameraRight.xy,0), cameraUp);
  cameraForward = normalize(InstancePosition.xyz + translation);
  viewPosition = viewMatrix * (InstancePosition.xyz + translation);
  viewPosition.xy += vertexPosition.xy * (InstancePosition.w + 1);
  screenPosition = vec4(projectionMatrix * viewPosition, 1);
  texCoord = vertexPosition.xy;

  // save some data from this vertex for use in fragment shaders
  // vertexNormal = VertexNormal;
  // vertexColor = VertexColor;

  return screenPosition;
}

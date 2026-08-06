// written by groverbuger for g3d
// MIT license

attribute vec3 InstancePosition;
uniform lowp float[6] projectionArray;
uniform mat3 viewMatrix;
uniform mat4 modelMatrix;

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;
//attribute vec4 groupId;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec3 worldPosition;
varying vec3 viewPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
  // calculate the positions of the transformed coordinates on the screen
  // save each step of the process, as these are often useful when writing custom fragment shaders
  vec4 screenPosition;
  worldPosition = (modelMatrix * vertexPosition).xyz;
  worldPosition += InstancePosition;
  viewPosition = viewMatrix * worldPosition;
  mat4 secondMat = mat4(
    vec4(projectionArray[0],projectionArray[1],0.,0.),
    vec4(0.,projectionArray[2],projectionArray[3],0.),
    vec4(0.,0.,projectionArray[4],projectionArray[5]),
    vec4(0.,0.,-1.,0.)
  );
  screenPosition =  vec4(viewPosition,1) * secondMat;

  // save some data from this vertex for use in fragment shaders
  vertexNormal = VertexNormal;
  vertexColor = VertexColor;

  return screenPosition;
}

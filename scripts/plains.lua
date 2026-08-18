local g3d = require 'g3d'

local mesh = {}
local w,h = 64,64
local pow = 1.5
do
  local meshn = 1
  for z=-h/2 + (h/2)%1,h/2- (h/2)%1 do
    for x=-w/2 + (w/2)%1,w/2-.5 - (w/2)%1 do
      --mesh[meshn] = {math.abs(x)^pow * (x<0 and -1 or 1),0,math.abs(z)^pow * (z<0 and -1 or 1)}
      local dist = (x^2+z^2)^.5
      mesh[meshn] = {x*dist,0,z*dist}
      meshn = meshn + 1
    end
  end
end

local map = {}
local dist = (w^pow)^2
local band = bit.bor
local function addMap(i1,i2,i3)
  local m1 = mesh[i1]
  local m2 = mesh[i2]
  local m3 = mesh[i3]
  if band(
    m1[1]^2+m1[3]^2 - dist,
    m2[1]^2+m2[3]^2 - dist,
    m3[1]^2+m3[3]^2 - dist)<0 then -- if any is negative
    map[#map + 1] = i1
    map[#map + 1] = i2
    map[#map + 1] = i3
  end
end
for y=0,(h-2) do
  for x=1,(w-1) do
    --if math.random(2)==1 then goto continue end
    local diag = (x - w / 2) * (y - h / 2) > 0
    if diag then
      addMap(
        x + 1 + w * (y+1),
        x + 1 + w * y,
        x + w * (y+1))
      addMap(
        x + w * y,
        x + 1 + w * y,
        x + w * (y+1))
    else
      addMap(
        x + w * y,
        x + w * (y+1),
        x + 1 + w * (y+1))
      addMap(
        x + w * y,
        x + 1 + w * y,
        x + 1 + w * (y+1))
    end
  end
end

local model = g3d.newModel(mesh)
model.mesh:setVertexMap(map)

local shader = love.graphics.newShader[[
varying vec3 worldPosition;
#ifdef VERTEX
// written by groverbuger for g3d
// MIT license

attribute vec3 InstancePosition;
uniform lowp float[6] projectionArray;
uniform mat3 viewMatrix;
uniform mat4 modelMatrix;
uniform Image heightMap1;
uniform Image heightMap2;
uniform Image heightMap3;

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec3 viewPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
  vec4 R;
  vec2 pos = vec2(modelMatrix[3].x, modelMatrix[3].z);
  worldPosition = (modelMatrix * (vertexPosition - vec4(pos.x,0.,pos.y,0.))).xyz;
  pos -= worldPosition.xz;
  pos /= 256;
  //height function
  worldPosition.y +=
/*
 sin((pos.y+pos.x)*.0115)
+sin((pos.y-pos.x)*.145)
+sin((pos.x-pos.y+.123)*.05)
-sin((pos.y+pos.x+.5155)*.0215)+
//*/
  Texel(heightMap1,pos/10.49287354).r*30
 +Texel(heightMap2,pos/3.189723461).r*10
 +Texel(heightMap3,pos/15.59287354).r*50
;
worldPosition.y -= (30+10+50-20);

  viewPosition = viewMatrix * worldPosition;
  mat4 secondMat = mat4(
    vec4(projectionArray[0],projectionArray[1],0.,0.),
    vec4(0.,projectionArray[2],projectionArray[3],0.),
    vec4(0.,0.,projectionArray[4],projectionArray[5]),
    vec4(0.,0.,-1.,0.)
  );
  worldPosition.y -= modelMatrix[3].y;
  R = vec4(viewPosition,1) * secondMat;
  worldPosition.y /= 64;
  worldPosition.y += .5;

  vertexNormal = VertexNormal;
  vertexColor = VertexColor;
#endif
#ifdef PIXEL
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
  vec4 texcolor = Texel(tex, texture_coords);
  vec4 R = vec4(1-worldPosition.y/2, 1-worldPosition.y, 1-worldPosition.y/2, 1.);
#endif
return R;}
]]

table.insert(g3d.shader.list, shader)

local heightMaps = {}

for i=1,1 do
  local heightMap = love.graphics.newCanvas(32,32, {format = "r8", msaa = 0})
  love.graphics.setCanvas(heightMap)
  for x=1,32 do
    local last = math.random()
    for y=1,32 do
      local Last = last
      last = math.random()
      love.graphics.setColor(1,1,1,(last+Last)/2)
      love.graphics.points(x,y)
    end
  end
  love.graphics.setCanvas()
  --heightMap:setFilter("nearest", "nearest")
  heightMap:setWrap("repeat","repeat")
  --heightMap:setWrap("clampzero","clampzero")
  shader:send("heightMap" .. i, heightMap)
  --plainsHeight:send("heightMap" .. i, heightMap)
  heightMaps[#heightMaps+1] = heightMap:newImageData()
end

return {
  draw = function ()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader(shader)
    model:updateMatrixTranslation()
    shader:send("modelMatrix", model.matrix)
    love.graphics.draw(model.mesh)
    love.graphics.setShader()
  end,
}

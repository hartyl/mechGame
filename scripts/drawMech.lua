local g3d = require 'g3d'
local line = g3d.newModel {
  { 0,   0, 0 },
  { .06, 0, 0 },
  { 0,   0, 0 },
}
local tw = 2 ^ 8
local ver = { { 0, tw, 0 } }
local resolution = 4
for i = 0, math.pi * 2, math.pi * 2 / resolution do
  ver[#ver + 1] = { math.cos(i), 0, math.sin(i) }
end
--ver[#ver+1] = {math.cos(0),0,math.sin(0)}
local shadow = g3d.newModel(ver --)--
, nil, nil, nil, nil, nil, nil, "fan")
--[[
shadow.mesh:setVertexMap{
  1,2,4,
  1,3,4,
  1,3,5,
  1,5,2,
  --3,2,4,
} --]]
shadow:setRotation(math.pi / 4, math.pi / 4, math.pi / 4)

local circle = g3d.newModel("circle.obj")
--local dir = {1,1,1}
local sPos = { { 0, 0, 0 } }
shadow:instanciate(sPos)
local function myStencilFunction()
  love.graphics.setDepthMode("gequal", false)
  love.graphics.setMeshCullMode "back"
  shadow:draw()
end
--local can = love.graphics.newCanvas()
local function drawS(self)
  --sPos = {}
  local p = { g3d.vector.unpack(self.pos) }
  p[4] = self.size - 1
  sPos[#sPos + 1] = p
end
shadow.shader = love.graphics.newShader(g3d.shader.path, [[
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords){
  return color;
}]])

table.insert(g3d.shader.list, shadow.shader)
shadow:setScale(.4)
function DrawShadows()
  --shadow:instanciate(sPos, { { "InstancePosition", "float", 3 } })
  --do return end
  local color = { love.graphics.getColor() }
  love.graphics.setStencilTest("equal", 0)
  love.graphics.setColor(0, 0, 0, .1)
    love.graphics.setShader(shadow.shader)
  for _, pos in next, sPos do
    shadow:setTranslation(g3d.vector.unpack(pos))
    --shadow:setScale(pos[4])
    love.graphics.stencil(myStencilFunction, "replace")
    love.graphics.setMeshCullMode "front"
    shadow:updateMatrixTranslation()
    love.graphics.draw(shadow.mesh)
  end

  love.graphics.setMeshCullMode "none"
  love.graphics.setStencilTest()
  love.graphics.setColor(color)
  love.graphics.setDepthMode("lequal", true)
  sPos = {}
end

local function drawP(self)
  local d, p = g3d.camera.getDirectionPitch()
  circle:setRotation(-p, math.pi / 2 - d, 0)
  circle.translation:copy(self.pos)
  circle:setScale(self.size)
  circle:draw()
  --lg.circle("line", self.pos.x, self.pos.y+self.pos.z/2, size)
  drawS(self)
end

local function drawL(self, other)
  line.translation:copy(self.pos)
  --.x, self.pos.y+self.pos.z/2, other.pos.x, other.pos.y+other.pos.z/2) =
  line.mesh:setVertices({ other.pos - self.pos }, 3, 1)
  line:draw()
  --lg.line(self.pos.x, self.pos.y+self.pos.z/2, other.pos.x, other.pos.y+other.pos.z/2)
end

return { drawP, drawL }

local g3d = require 'g3d'
local line = g3d.newModel {
  {0,0,0},
  {.06,0,0},
  {0,0,0},
}
local circle = g3d.newModel("circle.obj")
local function drawP(self, size)
  local d,p = g3d.camera.getDirectionPitch()
  circle:setRotation(-p,math.pi/2-d,0)
  circle.translation:setV(self.pos)
  circle:setScale(size)
  circle:draw()
  --lg.circle("line", self.pos.x, self.pos.y+self.pos.z/2, size)
end

local function drawL(self, other)
  line.translation:setV(self.pos)
  --.x, self.pos.y+self.pos.z/2, other.pos.x, other.pos.y+other.pos.z/2) =
  line.mesh:setVertices({other.pos- self.pos}, 3,1)
  line:draw()
  --lg.line(self.pos.x, self.pos.y+self.pos.z/2, other.pos.x, other.pos.y+other.pos.z/2)
end

return {drawP, drawL}

local vec = require 'g3d'.vector
local unpack = vec.unpack
---@class part
local PART = {}
PART.__index = PART

local gravity = vec{0,1,0}

function PART.getFloor(x)
  return 0
end

function PART:applyG( dt)
  local gnd = PART.getFloor(self.pos.x)
  if self.pos.y < gnd then
    self.air = .5
    self.gnd = self.gnd - dt
    self.pos = self.pos + gravity * dt
  else
    self.air = self.air - dt
    self.gnd = .5
    self.pos.y = gnd
    self.Pos = (self.pos+self.Pos ) * .5
    --self.Pos.x = self.pos.x
    --self.Pos.z = self.pos.z
    --self.Pos.y = self.pos.y
  end
end

function PART:applyS(dt)
  local Pos = self.pos
  self.pos = self.pos + (self.pos - self.Pos)
  self.Pos = Pos
end

--[[ function PART:stick(other)
  self.pos = other.pos + {
    vec.scale(32,vec.normalize(
    vec.unpack(self.pos - other.pos)
  ))} end]]

function PART:dstick(other, length, weight)
  weight = weight or .5
  local aweight = 1-weight
  local mid = self.pos * weight + other.pos * aweight
  self.pos = mid + length * aweight *
  vec{vec.normalize( unpack(self.pos - mid))}
  other.pos = mid + length * weight *
  vec{vec.normalize( unpack(other.pos - mid))}
  --[[
  local delta = length *
  vec{vec.normalize( unpack(self.pos - mid))}
  self.pos = mid + delta * aweight
  other.pos = mid - delta * weight
  --]]
  return mid
end

function PART:transferS(other, dir, weight)
  weight = weight or 1
  self.pos = self.pos + dir * weight
  other.pos = other.pos - dir * (2-weight)
end

return function(pos)
  return setmetatable({
    pos = vec(pos),
    Pos = vec{unpack(pos)},
    air = 0,
    gnd = 0,
    len = nil,
  },PART)
end

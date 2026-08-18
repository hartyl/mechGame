local vec = require 'g3d'.vector
local unpack = vec.unpack
---@class part
local PART = {}
PART.__index = PART

local gravity = vec { 0, .5, 0 }

function PART:getFloor()
  return 0 - self.size
end

function PART:applyG(dt)
  local gnd = self:getFloor()
  if self.pos.y < gnd then
    self.air = 1
    self.gnd = math.max(self.gnd - dt*2, 0)
    self.pos = self.pos + gravity * dt
  else
    self.air = math.max(self.air - dt*2, 0)
    self.gnd = 1
    --self.pos = self.Pos
    self.pos.y = gnd
    --self.Pos = (self.pos + self.Pos) * .5
    self.Pos:copy(self.pos)
  end
end

function PART:applyS(dt)
  self:applyG(dt)
  local Pos = self.pos
  local spd = (self.pos - self.Pos)
  local y = spd.y
  --spd = spd * self.air
  --spd = spd * (1-self.gnd*.1)
  spd.y = y
  self.pos = self.pos + spd
  self.Pos = Pos
end

--[[ function PART:stick(other)
  self.pos = other.pos + {
    vec.scale(32,vec.normalize(
    vec.unpack(self.pos - other.pos)
  ))} end]]
function PART:dstick(other, length, weight)
  weight = weight or .5
  local aweight = 1 - weight
  local mid = self.pos * weight + other.pos * aweight
  self.pos = mid + length * aweight *
      vec { vec.normalize(unpack(self.pos - mid)) }
  other.pos = mid + length * weight *
      vec { vec.normalize(unpack(other.pos - mid)) }
  --local gnd = math.max(self.gnd, other.gnd)
  --self.gnd = gnd
  --other.gnd = gnd
  --[[
  local delta = length *
  vec{vec.normalize( unpack(self.pos - mid))}
  self.pos = mid + delta * aweight
  other.pos = mid - delta * weight
  --]]
  return mid
end

function PART:push(other, length, weight)
  if -(self.pos - other.pos) > length then return end
  return self:dstick(other, length, weight)
end

function PART:pull(other, length, weight)
  if -(self.pos - other.pos) < length then return end
  return self:dstick(other, length, weight)
end

function PART:transferS(other, dir, weight)
  weight = weight or 1
  self.pos = self.pos + dir * weight
  other.pos = other.pos - dir * (2 - weight)
end

---@param pos vector
---@param size number?
---@param len number?
return function(pos, size, len)
  return setmetatable({
    pos = vec(pos),
    Pos = vec { unpack(pos) },
    air = 0,
    gnd = 0,
    size = size,
    len = len,
    last = vec(pos),
    next = vec(pos),
    parent = nil,
    weight = 1,
  }, PART)
end

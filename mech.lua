mx, my = 0, 0
b = false
local vec = require 'g3d'.vector
local newPart = require 'scripts.part'
local hipLen = .3
local mech = {
  body = newPart({ 0, -3, 0 }, hipLen * .5 * .6),
  hip1 = newPart({ 8, 0, 0 }, .25),
  hip2 = newPart({ -8, 0, 0 }, .25),
  knee1 = newPart({ 0, -2, 0 }, .25, .9),
  knee2 = newPart({ 0, -2, 0 }, .25, .9),
  foot1 = newPart({ 0, -2, 0 }, .25, .9),
  foot2 = newPart({ 0, -2, 0 }, .25, .9),
  tummy = newPart({ 0, -1, 0 }, .15),
  chest = newPart({ 0, 1, 0 }, hipLen * .5 * .6),
  shoulder1 = newPart({ 0, 1, 0 }, .15),
  shoulder2 = newPart({ 0, 1, 0 }, .15),
  head = newPart({ 0, 1, 0 }, .25),
}
local body = mech.body
body.parent = { pos = { 0, 0, 0 } }
local hip1 = mech.hip1
hip1.parent = body
local hip2 = mech.hip2
hip2.parent = body
local knee1 = mech.knee1
knee1.parent = hip1
local knee2 = mech.knee2
knee2.parent = hip2
local foot1 = mech.foot1
foot1.parent = knee1
local foot2 = mech.foot2
foot2.parent = knee2
local tummy = mech.tummy
tummy.parent = body
local chest = mech.chest
chest.parent = tummy
mech.head.parent = chest
local shoulder1 = mech.shoulder1
shoulder1.parent = chest
local shoulder2 = mech.shoulder2
shoulder2.parent = chest
mech.forward = vec { -1, 0, 0 }
mech.right = vec { 0, 0, -1 }
tummy.len = hipLen
chest.len = hipLen * .5
mech.head.len = hipLen * .5

local shoulderLen = .6
local walking = require 'scripts.animation' "animations/Walking.obj"
local startWalking = require 'scripts.animation' "animations/Start Walking.obj"
local stopWalking = require 'scripts.animation' "animations/Stop Walking.obj"
local run = require 'scripts.animation' "animations/run.obj"
local fcurves = stopWalking
local frame = 20

local order = 0
local iframe = 1
local mirror = false
local speed = 1
local mul = .3
function mech.update(dt)
  frame = frame + 24 * dt * speed
  if iframe >= #fcurves.Middle["Hips"] then
    frame = 1
    iframe = 0
    if fcurves == walking then
      if not K.up then
        fcurves = stopWalking
      end
      mirror = not mirror
    elseif fcurves == stopWalking then
      if K.up then
        fcurves = startWalking
        mirror = not mirror
      else
        frame = #fcurves.Middle["Hips"]
      end
    elseif fcurves == startWalking then
      fcurves = walking
      mirror = not mirror
    end
  end
  local pf = frame - iframe
  local nf = 1 - (frame - iframe)
  local fcurve
  if iframe ~= math.floor(frame) then
    iframe = math.floor(frame)
    pf = frame - iframe
    nf = 1 - (frame - iframe)
    function fcurve(self, boneName)
      local pos
      local s
      if boneName:find "Left" then
        s = boneName:sub(5)
        pos = mirror and "Right" or "Left"
      elseif boneName:find "Right" then
        s = boneName:sub(6)
        pos = mirror and "Left" or "Right"
      else
        s = boneName
        pos = "Middle"
      end
      self.last = self.next
      self.lastMirror = self.nextMirror
      self.next = vec(fcurves[pos][s][iframe])
      self.nextMirror = mirror
      self.len = -(self.next)
      local r
      r = self.last * nf * { self.lastMirror and -1 or 1, 1, 1 }
      r = r + self.next * pf * { self.nextMirror and -1 or 1, 1, 1 }
      return r
    end
  else
    function fcurve(self)
      local r
      r = self.last * nf * { self.lastMirror and -1 or 1, 1, 1 }
      r = r + self.next * pf * { self.nextMirror and -1 or 1, 1, 1 }
      return r
    end
  end
  body.parent.pos = vec { 0, 0, 0 }
  mul = mul + ((K.b and 1 or 0) - (K.v and 1 or 0)) * .001
  local function lFcurve(self, name, str)
    local delta = (fcurve(self, name) + self.parent.pos - self.pos) * (mul * (str or 1))
    self.pos = self.pos + delta * (1-math.min(1,self.gnd*10))
    self.parent.pos = self.parent.pos - delta
  end
  if not K.x then
    lFcurve(mech.head, "Head")
    lFcurve(chest, "Neck")
    lFcurve(tummy, "Spine1")
    lFcurve(hip1, "LeftUpLeg")
    lFcurve(hip2, "RightUpLeg")
    lFcurve(knee1, "LeftLeg", 1.3)
    lFcurve(knee2, "RightLeg", 1.3)
    lFcurve(foot1, "LeftFoot", 1)
    lFcurve(foot2, "RightFoot", 1)
    lFcurve(shoulder1, "LeftShoulder")
    lFcurve(shoulder2, "RightShoulder")
    --foot1.size = ((fcurves[not mirror and "Left" or "Right"]["ToeBase"][iframe][2])*1)
    --foot2.size = ((fcurves[not mirror and "Right" or "Left"]["ToeBase"][iframe][2]))*1
  end

  order = 1 --- order

  --forward
  --local t = (tummy.pos - body.pos)
  --local h = (hip1.pos - hip2.pos)
  --mech.up = vec { vec.normalize(vec.unpack(t)) }
  --mech.forward = vec { h:cross(mech.up) }
  --mech.right = vec { t:cross(mech.forward) }

  --do return end
  for hip, knee in next, { [hip1] = knee1, [hip2] = knee2 } do
    local dist = (knee.len ^ 2 + hipLen ^ 2) ^ .5
    tummy:push(knee, dist, .5)
    --constraint tummy to a ring
    dist = ((hipLen * .5) ^ 2 + (hipLen * .5) ^ 2) ^ .5 - .3
    tummy:push(hip, dist, .5)
  end
  --tummy:pull(body, tummy.len*1.2)

  --
  for i = order + 1, 2 - order, 1 - order - order do
    local knee = i == 1 and knee1 or knee2
    local hip = i == 1 and hip1 or hip2
    local foot = i == 1 and foot1 or foot2
    local shoulder = i == 1 and shoulder1 or shoulder2
    --attach
    knee:dstick(hip, knee.len) --.1 + .6 * knee.len)
    knee.right = vec {
      vec.normalize(
        (knee.pos - hip.pos):cross(mech.right)
      )
    }
    local pos = knee.right + knee.pos
    local fPos = foot.pos
    foot:push({ pos = pos, gnd = 0 }, foot.len * 1.5, 1)
    local spd = foot.pos - fPos
    knee.pos = knee.pos - spd
    knee:dstick(foot, foot.len)
    foot:push(hip, foot.len, .8)
    shoulder:dstick(chest, shoulderLen)
    shoulder:push(tummy, shoulderLen)
    shoulder:pull(hip, hipLen * 2)
  end
  --shoulder1:dstick(shoulder2, shoulderLen * 2)
  local bPos = body.pos
  --body:push({pos=hipMid, gnd=0}, .2)
  --body:pull({pos=hipMid, gnd=0}, .4)
  local bDel = body.pos - bPos
  hip1.pos = hip1.pos - bDel * .7
  hip2.pos = hip2.pos - bDel * .7

  mech.head:dstick(chest, mech.head.len)
  chest:dstick(tummy, chest.len)
  chest:push(body, chest.len * 1.2, .5)

  if love.keyboard.isDown "i" then
    body.pos.z = body.pos.z + .1
    knee1.pos.z = 0
    knee1.Pos.z = 0
    knee2.pos.z = 0
    knee2.Pos.z = 0
  end
  if love.keyboard.isDown "j" then
    tummy.pos.z = tummy.pos.z + .1
  end
  if love.keyboard.isDown "o" then
    body.pos.x = body.pos.x - .1
  end
  if love.keyboard.isDown "u" then
    --body.pos.y = body.pos.y - 10 * dt
    tummy.pos.y = tummy.pos.y - 5 * dt
  end
  if love.keyboard.isDown "y" then
    --body.pos.y = body.pos.y - 10 * dt
    tummy.pos.y = tummy.pos.y - 4 * dt
  end
  if love.keyboard.isDown "l" then
    foot1.pos.y = foot1.pos.y - 2 * dt
  end
  if love.keyboard.isDown "k" then
    foot2.pos.y = foot2.pos.y - 2 * dt
  end
  if love.keyboard.isDown "n" then
    knee1.pos.y = knee1.pos.y - 2 * dt
  end
  if love.keyboard.isDown "m" then
    knee2.pos.y = knee2.pos.y - 2 * dt
  end
  if love.keyboard.isDown "e" then
    tummy.pos = vec { 0, -3.5, 0 }
  end
  if love.keyboard.isDown "r" then
    body.pos = vec { 0, 0, 0 }
    tummy.pos = vec { 0, 0, 0 }
    chest.pos = vec { 0, 0, 0 }
    mech.head.pos = vec { 0, 0, 0 }
    hip1.pos = vec { 0, 0, 0 }
    hip2.pos = vec { 0, 0, 0 }
    knee1.pos = vec { 0, 0, 0 }
    knee2.pos = vec { 0, 0, 0 }
    foot1.pos = vec { 0, 0, 0 }
    foot2.pos = vec { 0, 0, 0 }
    shoulder1.pos = vec { 0, 0, 0 }
    shoulder2.pos = vec { 0, 0, 0 }

    body.Pos = vec { 0, 0, 0 }
    hip1.Pos = vec { 0, 0, 0 }
    hip2.Pos = vec { 0, 0, 0 }
    knee1.Pos = vec { 0, 0, 0 }
    knee2.Pos = vec { 0, 0, 0 }
    foot1.Pos = vec { 0, 0, 0 }
    foot2.Pos = vec { 0, 0, 0 }
    chest.Pos = vec { 0, 0, 0 }
    mech.head.Pos = vec { 0, 0, 0 }
  end

  knee1:applyS(dt)
  knee2:applyS(dt)
  foot1:applyS(dt)
  foot2:applyS(dt)
  hip1:applyS(dt)
  hip2:applyS(dt)
  body:applyS(dt)
  tummy:applyS(dt)
  chest:applyS(dt)
  mech.head:applyS(dt)
  shoulder1:applyS(dt)
  shoulder2:applyS(dt)
end

local drawP, drawL = unpack(require 'scripts.drawMech')
local lg = love.graphics

function mech.draw()
  drawP(body)
  drawP(tummy)
  drawP(chest)
  drawP(mech.head)
  lg.setColor(.2, .2, .2, 1)
  drawP(hip1)
  drawP(knee1)
  drawP(foot1)
  drawL(hip1, knee1)
  drawP(shoulder1)
  lg.setColor(0, 0, 0, 1)
  drawP(hip2)
  drawP(knee2)
  drawP(foot2)
  drawL(hip2, knee2)
  drawP(shoulder2)
  lg.setColor(1, 1, 1, 1)

  drawL(body, { pos = body.pos + mech.forward * 10 })
  drawL(body, { pos = body.pos + mech.right * 10 })
  --drawL({ pos = knee1.right + knee1.pos }, knee1)
  --drawL({ pos = knee2.right + knee2.pos }, knee2)
  local p1 = knee1.pos
  local p2 = hip2.pos
  drawL({ pos = vec { 1, - -(p1 - p2), 0 } }, { pos = { 1, 0, 0 } })
  lg.setShader()
  --lg.line(0, body.getFloor(0), Winw, body.getFloor(Winw))
  --lg.print(knee1.gnd .. "\n" .. knee2.gnd)
  lg.print(mul, 64, 32)
end

function love.mousepressed(...)
  mx, my, b = ...
end

return mech

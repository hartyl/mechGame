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
mech.forward = vec { 0, 0, -1 }
mech.right = vec { 1, 0, 0 }
tummy.len = hipLen
chest.len = hipLen * .5
mech.head.len = hipLen * .5

local shoulderLen = .6
local walking = require 'scripts.animation' "animations/Walking.obj"
local stopWalking = require 'scripts.animation' "animations/Stop Walking.obj"
local run = require 'scripts.animation' "animations/run.obj"
--walking = run
local fcurves = stopWalking
local frame = 20

local iframe = 1
local mirror = false
local speed = 1
local mul = .3
function mech.update(dt)
  frame = frame + 24 * dt * speed
  if iframe >= #fcurves.Middle["Hips"] then
    frame = 1
    iframe = 0
    if fcurves == walking or fcurves == run then
      if not K.w then
        fcurves = stopWalking
      end
      mirror = not mirror
    elseif fcurves == stopWalking then
      if K.w then
        mirror = not mirror
      else
        frame = #fcurves.Middle["Hips"] - 1
      end
    end
  end
  if fcurves ~= walking and K.w and not K.lctrl then
    fcurves = walking
    iframe = 1
    frame = 1
  end
  if fcurves ~= run and K.w and K.lctrl then
    fcurves = run
    iframe = 1
    frame = 1
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
      local n = vec(fcurves[pos][s][iframe])
      local m = (mirror and -1 or 1)
      local len = -(vec { n.z, 0, n.x }) * m
      local ang = math.atan2(n.z, n.x) * m + require 'g3d'.camera.getDirectionPitch()
      self.next = vec { 0, n.y, 0 }
      self.next.x = -math.sin(ang) * len
      self.next.z = math.cos(ang) * len
      self.len = -(self.next)
    end
  else
    function fcurve() end
  end
  body.parent.pos = vec { 0, 0, 0 }
  mul = mul + ((K.b and 1 or 0) - (K.v and 1 or 0)) * .001
  local function lFcurve(self, boneName, str)
    fcurve(self, boneName)
    local r
    r = self.last * nf
    r = r + self.next * pf
    local delta = (r + self.parent.pos - self.pos) * (mul * (str or 1))
    local d = 2
    self.pos = self.pos + delta * (((1 - self.gnd) + (d - 1)) / d)
    self.parent.pos = self.parent.pos - delta
  end
  if not K.x then
    lFcurve(chest, "Spine2", 2)
    lFcurve(tummy, "Spine", 2)
    lFcurve(hip1, "LeftUpLeg")
    lFcurve(hip2, "RightUpLeg")
    lFcurve(mech.head, "Head")
    lFcurve(knee1, "LeftLeg", 1.3)
    lFcurve(knee2, "RightLeg", 1.3)
    lFcurve(foot1, "LeftFoot", 2)
    lFcurve(foot2, "RightFoot", 2)
    lFcurve(shoulder1, "LeftShoulder")
    lFcurve(shoulder2, "RightShoulder")
  end
  for i, v in next, mech do
    if type(v) == "table" then
      if v.len then v:dstick(v.parent, v.len) end
      if v.applyS then v:applyS(dt) end
    end
  end
  if K.w then
    body.pos = body.pos + mech.forward * dt * 4
  end
end

local drawP, drawL = unpack(require 'scripts.drawMech')
local lg = love.graphics

function mech.draw()
  drawP(body)
  lg.setColor(.5, .5, .5, 1)
  drawP(tummy)
  drawP(chest)
  drawP(mech.head)
  lg.setColor(.2, .2, .2, 1)
  drawP(hip1)
  drawP(knee1)
  drawP(foot1)
  drawL(hip1, knee1)
  lg.setColor(.3, .3, .2, 1)
  drawP(shoulder1)
  lg.setColor(0, 0, 0, 1)
  drawP(hip2)
  drawP(knee2)
  drawP(foot2)
  drawL(hip2, knee2)
  lg.setColor(.2, .3, .3, 1)
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

return mech

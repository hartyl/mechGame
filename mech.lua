mx,my=0,0
b = false
local vec = require 'g3d'.vector
local newPart = require 'part'
local mech = {
  body = newPart { 0, 0, 0 },
  hip1 = newPart { 8, 0, 0 },
  hip2 = newPart { -8, 0, 0 },
  knee1 = newPart { 0, -2, 0 },
  knee2 = newPart { 0, -2, 0 },
  tummy = newPart { 0, -1, 0 },
  foot1 = newPart { 0, -2, 0 },
  foot2 = newPart { 0, -2, 0 },
}
local body = mech.body
local hip1 = mech.hip1
local hip2 = mech.hip2
local knee1 = mech.knee1
local knee2 = mech.knee2
local foot1 = mech.foot1
local foot2 = mech.foot2
local tummy = mech.tummy
mech.forward = vec { 1, 0, 0 }
mech.right = vec { 0, 0, 1 }

local hipLen = 1
knee1.len = 1
knee2.len = 1
foot1.len = 1
foot2.len = 1

local function clamp(m, M, n)
  return n < M and (n > m and n or m) or M
end

local fohilen = 2
local order = 0
function mech.update(dt)
  order = 1 --- order

  --forward
  local t = (tummy.pos - body.pos)
  local h = (hip1.pos - hip2.pos)
  mech.up = vec { vec.normalize(vec.unpack(t)) }
  mech.forward = vec { h:cross(mech.up) }
  mech.right = vec { t:cross(mech.forward) }

  for foot, knee in next, { [foot1] = knee1, [foot2] = knee2 } do
    local dist = (knee.len ^ 2 + hipLen ^ 2) ^ .5
    tummy:dstick(knee, math.max(dist, -(knee.pos - tummy.pos)), .5)
    foot:dstick(knee, foot.len, .5)
  end
  --constraint tummy to a ring
  -- [[
  local r = (hip2.pos - hip1.pos)
  r = r * -.2 * math.min(1, math.max(-1, vec.dotProduct(vec.unpackD(r, tummy.pos - body.pos))))
  tummy.pos = tummy.pos + r * 1.5
  r = r * (-1 / 2)
  hip1.pos = hip1.pos + r
  hip2.pos = hip2.pos + r
  --]]

  tummy:dstick(body, hipLen, 0.5)

  --
  for i = order + 1, 2 - order, 1 - order - order do
    local knee = i == 1 and knee1 or knee2
    local hip = i == 1 and hip1 or hip2
    local ohip = i == 2 and hip1 or hip2
    local side = i == 1 and -1 or 1
    local foot = i == 1 and foot1 or foot2
    local fohidist = vec.dotProduct(vec.unpackD(knee.pos - hip.pos, (hip1.pos-hip2.pos)))*side
    knee:dstick(ohip, -(knee.pos - ohip.pos) * (1 + fohidist *1 *dt))
    knee:dstick(hip, knee.len, .5) --.1 + .6 * knee.len)
    fohidist = vec.dotProduct(vec.unpackD(foot.pos - knee.pos, (hip1.pos-hip2.pos)))*side
    foot:transferS(knee,vec{(hip.pos-knee.pos):cross(mech.up)}*fohidist*dt*-3)
    --foot:dstick(ohip, -(foot.pos - ohip.pos) * (1 + fohidist *1 *dt))
    --foot:dstick(hip, -(foot.pos - hip.pos) * (1 + fohidist *1 *dt))
    if knee.pos.y > knee.getFloor(knee.pos) then
      --local spd = knee.Pos - knee.pos
      --knee.Pos = knee.pos - spd
    end
  end
  --local hipStr = 1*dt
  --hip1:transferS(hip2, mech.right * hipStr * math.max(0.1, (knee1.gnd + knee2.gnd)/2))
  local hipMid = hip1:dstick(hip2, hipLen, .5)
  local bPos = body.pos
  body.pos = (body.pos + hipMid) * .5
  local bDel = body.pos - bPos
  hip1.pos = hip1.pos - bDel * .7
  hip2.pos = hip2.pos - bDel * .7

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
    body.pos.y = body.pos.y - 10 * dt
  end
  if love.keyboard.isDown "e" then
    tummy.pos = vec { 0, -4, 0 }
  end
  if love.keyboard.isDown "r" then
    body.pos = vec { 0, 0, 0 }
    tummy.pos = vec { 0, 0, 0 }
    hip1.pos = vec { 0, 0, 0 }
    hip2.pos = vec { 0, 0, 0 }
    knee1.pos = vec { 0, 0, 0 }
    knee2.pos = vec { 0, 0, 0 }
    foot1.pos = vec { 0, 0, 0 }
    foot2.pos = vec { 0, 0, 0 }

    body.Pos = vec { 0, 0, 0 }
    hip1.Pos = vec { 0, 0, 0 }
    hip2.Pos = vec { 0, 0, 0 }
    knee1.Pos = vec { 0, 0, 0 }
    knee2.Pos = vec { 0, 0, 0 }
    foot1.Pos = vec { 0, 0, 0 }
    foot2.Pos = vec { 0, 0, 0 }
  end

  knee1:applyS(dt)
  knee2:applyS(dt)
  foot1:applyS(dt)
  foot2:applyS(dt)
  hip1:applyS(dt)
  hip2:applyS(dt)
  body:applyS(dt)
  tummy:applyS(dt)

  body:applyG(dt)
  tummy:applyG(dt)
  knee1:applyG(dt)
  knee2:applyG(dt)
  foot1:applyG(dt)
  foot2:applyG(dt)
  hip1:applyG(dt)
  hip2:applyG(dt)
end

local drawP, drawL = unpack(require 'drawMech')
local lg = love.graphics

function mech.draw()
  drawP(body, hipLen * .5 * .6)
  drawP(tummy, .25)
  lg.setColor(.2, .2, .2, 1)
  drawP(hip1, hipLen * .5 * .4)
  drawP(knee1, .25)
  drawP(foot1, .35)
  drawL(hip1, knee1)
  lg.setColor(0, 0, 0, 1)
  drawP(hip2, hipLen * .5 * .4)
  drawP(knee2, .25)
  drawP(foot2, .35)
  drawL(hip2, knee2)
  lg.setColor(1, 1, 1, 1)

  drawL(body, { pos = body.pos + mech.forward * 10 })
  drawL(body, { pos = body.pos + mech.right * 10 })
  drawL({ pos = vec { 0, -fohilen, 0 } }, { pos = { 0, 0, 0 } })
  local p1 = knee1.pos
  local p2 = hip2.pos
  drawL({ pos = vec { 1, - -(p1 - p2), 0 } }, { pos = { 1, 0, 0 } })
  lg.setShader()
  --lg.line(0, body.getFloor(0), Winw, body.getFloor(Winw))
  --lg.print(knee1.gnd .. "\n" .. knee2.gnd)
end

function love.mousepressed(...)
  mx,my,b = ...
end

return mech

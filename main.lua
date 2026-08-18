Winw, Winh = love.graphics.getDimensions()
K = {}
local g3d = require 'g3d'
local mech = require 'mech'
--local plains = require 'plains'
local plane = g3d.newModel {
  {-1,0,-1},
  {-1,0,1},
  {1,0,-1},
  {-1,0,1},
  {1,0,1},
  {1,0,-1},
}
plane:setScale(100)
local plane2 = g3d.newModel {
  {-1,0,-1},
  {-1,0,1},
  {1,0,-1},
  {-1,0,1},
  {1,0,1},
  {1,0,-1},
}
--plane:setTranslation(-50, 0, -50)
plane2:setRotation(math.pi/2,0,0)
plane2:setTranslation(-2, 2,5)
plane2:setScale(10,10,10)

LOL = 0

local camera = g3d.camera
camera.updateGameProjection()
camera.lookAt(0,-1,3,0,-1,4)
function love.update(dt)
  mech.update(dt)
  g3d.camera.firstPersonMovement(dt)
end

function love.draw()
  love.graphics.setColor(.5,.5,.5,1)
  plane:draw()
  love.graphics.setColor(1,1,1,1)
  plane2:draw()
  mech.draw()
  --plains.draw()
  DrawShadows()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setShader()
  love.graphics.print(love.timer.getFPS(), 64,64)
  --love.graphics.print(camera.position.x .. "\n" .. camera.position.y .. "\n" .. camera.position.z)
  love.graphics.print(mech.foot1.pos.y .. "\n" .. mech.foot1.pos.y .. "\n" .. camera.position.z)
end

local vec = require 'g3d'.vector

function love.mousemoved(_, _, dx, dy)
  camera.firstPersonLook(dx, dy, true)
end

local vec = require 'g3d'.vector

function love.mousemoved(_, _, dx, dy)
  camera.firstPersonLook(dx, dy, true)
  if love.mouse.isDown(1) then
    mech.tummy.pos = mech.tummy.pos + vec{dx/10,0,dy/10}
  end
end

function love.keypressed(k)
  K[k] = k == "escape" and love.event.quit() or true
end

function love.keyreleased(k)
  K[k] = false
end

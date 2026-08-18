-- written by groverbuger for g3d
-- MIT license

local newMatrix = require "matrices"
local vector = require "vector"
local shader = require "shader"

-- define the camera singleton
local tan, atan2 = math.tan, math.atan2
local sin, cos = math.sin, math.cos
local pi = math.pi
local min, max = math.min, math.max
local ceil = math.ceil
local function unpack3(t)
  return t[1], t[2], t[3]
end

local camera = {
  fov = pi / 2,
  nearClip = .01,
  farClip = 512,
  aspectRatio = love.graphics.getWidth() / love.graphics.getHeight(),
  target = vector { 1, 0, 0 },
  position = vector { 0, 0, 0 },
  positionPre = vector { 0, 0, 0 },
  up = vector { 0, 1, 0 },

  viewMatrix = newMatrix(),
  projectionMatrix = {}, --newMatrix(),
  speed = 9,
}

camera.zoom = 0
for i = 7, #camera.projectionMatrix do
  camera.projectionMatrix[i] = nil
end

---read-only variables, can't be set by the end user
local direction = 0
local pitch = 0

function camera.getDirectionPitch()
  return direction, pitch
end

-- convenient function to return the camera's normalized look vector
function camera.getLookVector()
  local vx, vy, vz = unpack3(camera.target - camera.position)
  local length = vector.magnitude(vx, vy, vz)
  -- make sure not to divide by 0
  length = (length > 0 and 1 / length or 1)

  return vx * length, vy * length, vz * length
end

-- give the camera a point to look from and a point to look towards
function camera.lookAt(x, y, z, xAt, yAt, zAt)
  camera.position:set(x, y, z)
  camera.target:set(xAt, yAt, zAt)

  -- update the fpsController's direction and pitch based on lookAt
  local dx, dy, dz = camera.getLookVector()
  direction = -atan2(dz, dx)
  pitch = -atan2(dy, (dx * dx + dz * dz) ^ .5)

  -- update the camera in the shader
  camera.updateViewMatrix()
end

-- move and rotate the camera, given a point and a direction and a pitch (vertical direction)
function camera.lookInDirection(directionTowards, pitchTowards, x, y, z)
  if x then camera.position:set(x,y,z) end
  direction = directionTowards or direction
  pitch = pitchTowards or pitch

  -- turn the cos of the pitch into a sign value, either 1, -1
  local cosPitch = cos(pitch)

  -- don't let cosPitch ever hit 0, because weird camera glitches will happen
  --cosPitch = (cosPitch < 0 and -1 or 1) * max(abs(cosPitch), 0.00001)

  -- convert the direction and pitch into a target point
  camera.target:set(
    vector.add(
      cos(direction) * cosPitch,
      sin(pitch),
      sin(direction) * cosPitch,
    vector.unpack(camera.position))
    )
  -- update the camera in the shader
  camera.updateViewMatrix()
end

-- recreate the camera's view matrix from its current values
function camera.updateViewMatrix()
  camera.viewMatrix:setViewMatrix(camera.position, camera.target, camera.up)
  camera.moved = true
end

-- recreate the camera's projection matrix from its current values
function camera.updateProjectionMatrix()
  local fov         = camera.fov
  local near        = camera.nearClip
  local far         = camera.farClip
  local aspectRatio = camera.aspectRatio
  local top         = near * tan(fov / 2)
  local bottom      = -1 * top
  local right       = top * aspectRatio
  local left        = -1 * right

  --asdasd
  local self        = camera.projectionMatrix
  self[1], self[2]  = 2 * near / (right - left), (right + left) / (right - left)
  self[3], self[4]  = 2 * near / (top - bottom), (top + bottom) / (top - bottom)
  self[5], self[6]  = -1 * (far + near) / (far - near), -2 * far * near / (far - near)
  --self[13], self[14], self[15], self[16] = 0, 0, -1, 0
  -- 2*near
  -- 1/(top-bottom)
  -- 1/(right-left)
end

function camera.updateGameProjection()
  camera.aspectRatio = Winw / Winh
  camera.zoom = max(min(pi * 27, camera.zoom), -pi * 49)
  camera.fov = min(pi * .8,
    (pi / 2 + camera.zoom / 100)
    * max(camera.aspectRatio, camera.aspectRatio ^ -1))
  camera.updateProjectionMatrix()
  for _, sh in next, shader.list do
    local m = camera.projectionMatrix
    sh:send("projectionArray", m[1], m[2], m[3], m[4], m[5], m[6])
  end
  --SelectionCanvasReset()

  --[[
  local scale = 2
  local width, height =
      ceil(Winw / scale),
      ceil(Winh / scale);
  local msaa = 2
  return love.graphics.newCanvas(
        width, height,
        { msaa = msaa }),
      love.graphics.newCanvas(
        width, height,
        { format = "stencil8", readable = false, msaa = msaa }
      )
  --]]
end

-- recreate the camera's orthographic projection matrix from its current values
--[[
function camera.updateOrthographicMatrix(size)
  camera.projectionMatrix:setOrthographicMatrix(camera.fov, size or 5,
    camera.nearClip, camera.farClip,
    camera.aspectRatio)
end
]]

-- simple first person camera movement with WASD
-- put this local function in your love.update to use, passing in dt

local Crux = -- [[
function (s) end
--]]Crux
function camera.firstPersonMovement(dt)
  local self = camera
  -- collect inputs
  Crux "start FPS"
  local speed = self.speed * (K['lctrl'] and 90 or 1)
  local moveX = (K["w"] and 1 or 0) + (K["s"] and -1 or 0)
  local moveZ = (K["d"] and 1 or 0) + (K["a"] and -1 or 0)
  local moveY = (K["lshift"] and 1 or 0) + (K["space"] and -1 or 0)
  Crux "  -- collect inputs"

  if moveY ~= 0 then
    self.position.y = self.position.y + moveY * speed * dt
    camera.moved = true
  end

  Crux "if moveZ"
  -- rotate input according to camera, make speed uniform on any direction
  if moveX ~= 0 or moveZ ~= 0 then
    local angle = atan2(moveZ, moveX)
    self.position.x = self.position.x + cos(direction + angle) * speed * dt
    self.position.z = self.position.z + sin(direction + angle) * speed * dt
    camera.moved = true
  end
  Crux "rotate according"

  -- update the camera's in the shader, unless unnecessary
  if camera.moved then
    self.lookInDirection()
    for _, sh in next, shader.list do
      shader.prepare(sh, camera)
    end
    camera.positionPre:copy(camera.position)
    Drawed = 1
    camera.moved = false
  end
  Crux "end"
end

local dpi = 1 / 300
-- use this in your love.mousemoved function, passing in the movements
function camera.firstPersonLook(dx, dy, lock)
  local sensitivity = camera.fov * dpi
  direction = direction + dx * sensitivity
  pitch = max(min(pitch + dy * sensitivity, pi * .5*.99), pi * -.5*.99)

  camera.lookInDirection()
  love.mouse.setRelativeMode(lock or false)
end

camera.updateProjectionMatrix()
camera.updateViewMatrix()
camera.updateGameProjection()
return camera

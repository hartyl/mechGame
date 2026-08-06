-- written by groverbuger for g3d
-- MIT license

local vector = require "vector"
local cross = vector.crossProduct
local vectorNormalize = vector.normalize
local unpack3 = vector.unpack
local unpack4 = function (t)
  return t[1], t[2], t[3], t[4]
end
--[[
local unpack = function(t)
  return
    t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8],
    t[9], t[10], t[11], t[12], t[13], t[14], t[15], t[16],
    t[17], t[18], t[19], t[20], t[21], t[22], t[23], t[24],
    t[25], t[26], t[27], t[28], t[29], t[30], t[31], t[32]
end
--]]

----------------------------------------------------------------------------------------------------
-- matrix class
----------------------------------------------------------------------------------------------------
--[[

 matrices are 16 numbers in table, representing a 4x4 matrix like so:
| 1   2   3   4  |
|                |
| 5   6   7   8  |
|                |
| 9   10  11  12 |
|                |
| 13  14  15  16 |

]]

local matrix = {}
matrix.__index = matrix
matrix.__metatable = "Matrix"

local function newMatrix()
  -- initialize a matrix as the identity matrix
  local self = setmetatable( {
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0,-1, 0,
    } , matrix)

  return self
end

-- automatically converts a matrix to a string
-- for printing to console and debugging
function matrix:__tostring()
  local s = {}
  for i=1,13,4 do
    s[#s+1] = table.concat(self, ";",i,i+3)
  end
  return table.concat(s, "\n")
end

----------------------------------------------------------------------------------------------------
-- transformation, projection, and rotation matrices
----------------------------------------------------------------------------------------------------
-- the three most important matrices for 3d graphics
-- these three matrices are all you need to write a simple 3d shader

function matrix:setTranslation(translation)
  -- translations
  self[4], self[8], self[12] = unpack3(translation)
end

local cos, sin = math.cos, math.sin
-- returns a transformation matrix
-- translation, rotation, and scale are all 3d vectors
function matrix:setTransformationMatrix(translation, rotation, scale)
  -- translations
  self:setTranslation(translation)

  -- rotations
  if #rotation == 3 then
    -- use 3D rotation vector as euler angles
    -- source: https://en.wikipedia.org/wiki/Rotation_matrix
    local cz, cy, cx            = cos(rotation[3]), cos(rotation[2]), cos(rotation[1])
    local sz, sy, sx            = sin(rotation[3]), sin(rotation[2]), sin(rotation[1])
    self[1], self[2], self[3]   = cz * cy, cz * sy * sx - sz * cx, cz * sy * cx + sz * sx
    self[5], self[6], self[7]   = sz * cy, sz * sy * sx + cz * cx, sz * sy * cx - cz * sx
    self[9], self[10], self[11] = -sy, cy * sx, cy * cx
  else
    -- use 4D rotation vector as a quaternion
    local qx, qy, qz, qw        = unpack4(rotation)
    self[1], self[2], self[3]   = 1 - 2 * qy ^ 2 - 2 * qz ^ 2, 2 * qx * qy - 2 * qz * qw, 2 * qx * qz + 2 * qy * qw
    self[5], self[6], self[7]   = 2 * qx * qy + 2 * qz * qw, 1 - 2 * qx ^ 2 - 2 * qz ^ 2, 2 * qy * qz - 2 * qx * qw
    self[9], self[10], self[11] = 2 * qx * qz - 2 * qy * qw, 2 * qy * qz + 2 * qx * qw, 1 - 2 * qx ^ 2 - 2 * qy ^ 2
  end

  -- scale
  local sx, sy, sz            = unpack3(scale)
  self[1], self[2], self[3]   = self[1] * sx, self[2] * sy, self[3] * sz
  self[5], self[6], self[7]   = self[5] * sx, self[6] * sy, self[7] * sz
  self[9], self[10], self[11] = self[9] * sx, self[10] * sy, self[11] * sz

  -- fourth row is not used, just set it to the fourth row of the identity matrix
  -- self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function matrix:getScale()
  -- does not account for negative scaling
  return
    vector.magnitude(self[1], self[5], self[9]),
    vector.magnitude(self[2], self[6], self[10]),
    vector.magnitude(self[3], self[7], self[11])
end

-- transpose of the camera (look at) matrix
function matrix:lookAtFrom(pos, target, up, orig_scale)
  self:setTranslation(pos)

  local sx, sy, sz
  if orig_scale then
    sx, sy, sz = unpack3(orig_scale)
  else
    sx, sy, sz = self:getScale()
  end

  -- forward, side, up directions
  local f_x, f_y, f_z         = vectorNormalize(unpack3(pos - target))
  local s_x, s_y, s_z         = vectorNormalize(cross(up[1], up[2], up[3], f_x, f_y, f_z))
  local u_x, u_y, u_z         = cross(f_x, f_y, f_z, s_x, s_y, s_z)

  self[1], self[2], self[3]   = f_x * sx, s_x * sy, u_x * sz
  self[5], self[6], self[7]   = f_y * sx, s_y * sy, u_y * sz
  self[9], self[10], self[11] = f_z * sx, s_z * sy, u_z * sz
end

----------------------------------------------------------------------------------------------------
-- camera transformations
----------------------------------------------------------------------------------------------------

-- returns a perspective projection matrix
-- (things farther away appear smaller)
-- all arguments are scalars aka normal numbers
-- aspectRatio is defined as window width divided by window height
function matrix:setProjectionMatrix(fov, near, far, aspectRatio)
  local top        = near * math.tan(fov / 2)
  local bottom     = -1 * top
  local right      = top * aspectRatio
  local left       = -1 * right

  --asdasd
  self[1], self[2] = 2 * near / (right - left), (right + left) / (right - left)
  self[3], self[4] = 2 * near / (top - bottom), (top + bottom) / (top - bottom)
  self[5], self[6] = -1 * (far + near) / (far - near), -2 * far * near / (far - near)
  --self[13], self[14], self[15], self[16] = 0, 0, -1, 0
  -- 2*near
  -- 1/(top-bottom)
  -- 1/(right-left)
end

-- returns a view matrix
-- eye, target, and up are all 3d vectors
function matrix:setViewMatrix(eye, target, up)
  local z = vector { vectorNormalize(unpack3(eye - target)) }
  assert(z)
  assert(z.x)
  assert(up)
  assert(up.cross)
  local x = vector { vectorNormalize(up:cross(z)) }
  assert(x)
  assert(x.x)
  self[1], self[2], self[3] = unpack3(x)
  self[5], self[6], self[7] = x:cross(z)
  self[9], self[10], self[11] = unpack3(z)
end

return newMatrix

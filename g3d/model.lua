-- written by groverbuger for g3d
-- MIT license

local newMatrix = require "matrices"
local loadObjFile = require "objloader"
local collisions = require "collisions"
local vector = require "vector"
local camera = require "camera"
local Shader = require "shader"
local vectorNormalize = vector.normalize

local lg = love.graphics

-------------------------------------------------------------------------------
-- define a model class
-------------------------------------------------------------------------------

---@class model
local model = {}
model.__index = model

-- define some default properties that every model should inherit
-- that being the standard vertexFormat and basic 3D shader
model.vertexFormat = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
  { "VertexNormal",   "float", 3 },
  { "VertexColor",    "byte",  4 },
  { "groupId",        "float", 1 },
}
model.shader = Shader.shader

-- this returns a new instance of the model class
-- a model must be given a .obj file or equivalent lua table, and a texture
-- translation, rotation, and scale are all 3d vectors and are all optional
---create a new model with metatable
---@param verts string|table
---@param texture string|love.Image?
---@param translation vector|table?
---@param rotation vector|table?
---@param scale vector|table?
---@param noMap boolean?
---@param vertexFormat table?
---@return table
local function newModel(verts, texture, translation, rotation, scale, noMap, vertexFormat, mode)
  local self = setmetatable({}, model)
  local map, bones

  self.texture = texture
  -- if verts is a string, use it as a path to a .obj file
  -- otherwise verts is a table, use it as a model defintion
  -- vertex handling, as a table
  if type(verts) == "string" then
    local spheres
    verts, map, spheres, bones = loadObjFile(verts, nil, nil, noMap)
    self.spheres = #spheres > 0 and spheres or nil
  end
  self.verts = verts
  self.vertexFormat = vertexFormat or self.vertexFormat
  self.mesh = lg.newMesh(self.vertexFormat, self.verts, mode or "triangles")
  self.mesh:setTexture(self.texture)
  if map then
    self.mesh:setVertexMap(map)
  end
  self.matrix = newMatrix()
  if type(scale) == "number" then scale = { scale, scale, scale } end
  if not translation then
    translation = vector { 0, 0, 0 }
  elseif getmetatable(translation) ~= vector.mt then
    translation = vector(translation)
  end
  if not rotation then
    rotation = vector { 0, 0, 0, 0 }
  elseif getmetatable(rotation) ~= vector.mt then
    rotation = vector(rotation)
  end
  if not scale then
    scale = vector { 1, 1, 1 }
  elseif getmetatable(scale) ~= vector.mt then
    scale = vector(scale)
  end
  self:setTransform(translation, rotation, scale)

  --[[
  if bones then
    self.bones = bones; self.bonesPre = bones
  end
  --]]

  return self
end

-- populate model's normals in model's mesh automatically
-- if true is passed in, then the normals are all flipped
function model:makeNormals(isFlipped)
  for i = 1, #self.verts, 3 do
    if isFlipped then
      self.verts[i + 1], self.verts[i + 2] = self.verts[i + 2], self.verts[i + 1]
    end

    local vp = vector(self.verts[i])
    local v = vector(self.verts[i + 1])
    local vn = vector(self.verts[i + 2])

    local n_1, n_2, n_3 = vectorNormalize(
      (v - vp):cross(vn - v)
    )
    vp[6], v[6], vn[6] = n_1, n_1, n_1
    vp[7], v[7], vn[7] = n_2, n_2, n_2
    vp[8], v[8], vn[8] = n_3, n_3, n_3
  end

  self.mesh = lg.newMesh(self.vertexFormat, self.verts, "triangles")
  self.mesh:setTexture(self.texture)
end

-- move and rotate given two 3d vectors
function model:setTransform(translation, rotation, scale)
  self.translation = translation and vector(translation) or self.translation
  self.rotation = vector(rotation) or self.rotation
  self.scale = vector(scale) or self.scale
  self:updateMatrix()
end

-- move given one 3d vector
function model:setTranslation(tx, ty, tz)
  self.translation.x = tx
  self.translation.y = ty
  self.translation.z = tz
  self:updateMatrix()
end

-- rotate given one 3d vector
-- using euler angles
function model:setRotation(...)
  local r = self.rotation
  r[1], r[2], r[3], r[4] = ...
  self:updateMatrix()
end

-- create a quaternion from an axis and an angle
function model:setAxisAngleRotation(x, y, z, angle)
  x, y, z = vectorNormalize(x, y, z)
  angle = angle / 2

  local r = self.rotation
  r.x = x * math.sin(angle)
  r.y = y * math.sin(angle)
  r.z = z * math.sin(angle)
  r.w = math.cos(angle)

  self:updateMatrix()
end

-- resize model's matrix based on a given 3d vector
function model:setScale(...)
  local s = self.scale
  if select(2, ...) and select(3, ...) then
    s.x, s.y, s.z = ...
  else
    local x = ...
    s.x, s.y, s.z = x, x, x
  end
  self:updateMatrix()
end

-- update the model's transformation matrix
function model:updateMatrix()
  self.matrix:setTransformationMatrix(
    self.translation - camera.position,
    self.rotation,
    self.scale)
end

-- update model's matrix position
function model:updateMatrixTranslation()
  local m = self.matrix
  m[4], m[8], m[12] = vector.unpack(self.translation - camera.position)
end

-- align's the model matrix to a given point
-- up vector is assumed to be normalized
function model:lookAtFrom(pos, target, up)
  pos = pos or self.translation
  self.matrix:lookAtFrom(pos, target, up or vector { 0, 0, 1 }, self.scale)
end

function model:lookAt(target, up)
  self.matrix:lookAtFrom(self.translation, target, up or vector { 0, 0, 1 }, self.scale)
end

-- draw the model
function model:draw(shader)
  shader = shader or self.shader
  lg.setShader(shader)
  self:updateMatrixTranslation()
  shader:send("modelMatrix", self.matrix)
  lg.draw(self.mesh)
end

---create a mesh with positions or smthing
---@param positions table
---@param format table?
---@param mode string?
---@return love.Mesh
---@nodiscard
function model.newInstanceMesh(positions, format, mode)
  return love.graphics.newMesh(
    format or { { "InstancePosition", "float", 3 } },
    positions,
    nil,
    mode or "static")
end

---helper function
---@param mesh love.Mesh
function model:reinstanciate(mesh)
  self.instanceMesh = mesh
  self.mesh:attachAttribute("InstancePosition", mesh, "perinstance")
end

---set multiple positions for self
---@param positions table
---@return love.Mesh
function model:instanciate(positions)
  self.positions = positions
  self:reinstanciate(self.newInstanceMesh(positions))
  return self.instanceMesh
end

---draw an object with explicit instances
function model:drawInstanced(shader)
  shader = shader or self.shader
  lg.setShader(shader)
  self:updateMatrixTranslation()
  shader:send("modelMatrix", self.matrix)
  lg.drawInstanced(self.mesh, #self.positions)
  lg.setShader()
end

function model:drawBillboard(shader)
  shader = shader or self.shader
  lg.setShader(shader)
  shader:send("translation", self.translation - camera.position)
  lg.draw(self.mesh)
  lg.setShader()
end

function model:drawBillboardInstanced(shader)
  shader = shader or self.shader
  lg.setShader(shader)
  shader:send("translation", self.translation - camera.position)
  lg.drawInstanced(self.mesh, #self.positions)
  lg.setShader()
end

function model:drawMultiple(shader, positions)
  shader = shader or self.shader
  lg.setShader(shader)
  local prevInstaMesh = self.instanceMesh
  local instaMesh = self.newInstanceMesh(positions)
  self:reinstanciate(instaMesh)
  shader:send("modelMatrix", self.matrix)
  lg.drawInstanced(self.mesh, #positions)
  if prevInstaMesh then
    self:reinstanciate(prevInstaMesh)
  end
  lg.setShader()
end

-- the fallback function if ffi was not loaded

-- makes models use less memory when loaded in ram
-- by storing the vertex data in an array of vertix structs instead of lua tables
-- requires ffi
-- note: throws away the model's verts table

function model:rayIntersection(...)
  return collisions.rayIntersection(self.verts, self, ...)
end

function model:isPointInside(...)
  return collisions.isPointInside(self.verts, self, ...)
end

function model:sphereIntersection(...)
  return collisions.sphereIntersection(self.verts, self, ...)
end

function model:closestPoint(...)
  return collisions.closestPoint(self.verts, self, ...)
end

function model:capsuleIntersection(...)
  return collisions.capsuleIntersection(self.verts, self, ...)
end

return newModel

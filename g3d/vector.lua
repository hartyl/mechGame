-- written by groverbuger for g3d
-- MIT license

----------------------------------------------------------------------------------------------------
-- vector functions
----------------------------------------------------------------------------------------------------
-- some basic vector functions that don't use tables
-- because these functions will happen often, this is done to avoid frequent memory allocation

local function unpack3(t)
  return t[1], t[2], t[3]
end

local function unpackD(t1, t2)
  return
      t1[1], t1[2], t1[3],
      t2[1], t2[2], t2[3]
end
---@class vector
local vector = {}
do
  local k = { 1, 2, 3, 4, x = 1, y = 2, z = 3, w = 4 }
  vector = {
    __index = function(self, key)
      return rawget(self, rawget(k, key)) or rawget(vector, key)
    end,
    --__index = vector,
    __newindex = function(self, key, value)
      --assert(rawget(k, key), "vector has not this key")
      rawset(self, rawget(k, key), value)
    end,
    --__metatable = "lmao",
  }
end
vector = setmetatable(vector, {
  ---new vector
  __call = function(_, v)
    return setmetatable(v, vector)
  end
})

function vector.__sub(a, b)
  return vector { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end

function vector.__add(a, b)
  return vector { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
end

function vector.subtract(v1, v2, v3, v4, v5, v6)
  return v1 - v4, v2 - v5, v3 - v6
end

function vector.add(v1, v2, v3, v4, v5, v6)
  return v1 + v4, v2 + v5, v3 + v6
end

function vector:set(...)
  self[1], self[2], self[3] = ...
end

function vector:copy(other)
  self[1], self[2], self[3] = other[1], other[2], other[3]
end

---multiply a vector with a number
function vector.scale(scalar, v1, v2, v3)
  return v1 * scalar, v2 * scalar, v3 * scalar
end

---multiply two vectors or a vector with a number
function vector.__mul(a, b)
  if type(b) == "number" then
    return vector { vector.scale(b, unpack3(a)) }
  end
  if type(a) == "number" then
    return vector { vector.scale(a, unpack3(b)) }
  end
  return vector { a[1] * b[1], a[2] * b[2], a[3] * b[3] }
end

---divide two vectors
function vector.__div(a, b)
  return vector { a[1] / b[1], a[2] / b[2], a[3] / b[3] }
end

---cross two sets of numbers
function vector.crossProduct(a1, a2, a3, b1, b2, b3)
  return a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1
end

---dot product between two sets of numbers
function vector.dotProduct(a1, a2, a3, b1, b2, b3)
  return a1 * b1 + a2 * b2 + a3 * b3
end

function vector.magnitude(x, y, z)
  return (x ^ 2 + y ^ 2 + z ^ 2) ^ .5
end

function vector.normalize(x, y, z)
  local mag = vector.magnitude(x, y, z)
  if mag ~= 0 then
    return x / mag, y / mag, z / mag
  else
    return 0, 0, 0
  end
end

---cross two vectors and return raw unpacked data
function vector:cross(other)
  return vector.crossProduct(unpackD(self, other))
end

---get the scalar size of the vector
function vector:__unm()
  return vector.magnitude(unpack3(self))
end

vector.unpack = unpack3
vector.unpackD = unpackD

return vector

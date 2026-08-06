-- written by groverbuger for g3d
-- MIT license

--[==========================[--
             __       __
           /´ _`\    /\ \
       __ /\_\L\ \   \_\ \
     /´ _`\/#/_\_<_  /´_` \
    /\ \L\`\/\ \L\ \/\ \L\ \
    \ \____`\`\____/\ \___,_\
     \/###L\`\/###/  \/##,V#/
       /\____/
       \/###/

--]==========================] --

local pathpre = package.path
-- so that far polygons don't overlap near polygons
love.graphics.setDepthMode("lequal", true)
package.path  = (...):gsub("%.", "/") .. "/?.lua"
return {
  _VERSION     = "g3d 1.5.2",
  _DESCRIPTION = "Simple and easy 3D engine for LÖVE.",
  _URL         = "https://github.com/groverburger/g3d",
  _LICENSE     = [[
    MIT License

    Copyright (c) 2022 groverburger

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]],
  path         = (...):gsub("%/", "."),

  vector       = require "vector",
  newMatrix    = require "matrices",
  newModel     = require "model",
  camera       = require "camera",
  collisions   = require "collisions",
  loadObj      = require "objloader",
-- the shader is what does the heavy lifting, displaying 3D meshes on your 2D monitor
  shader       = require "shader",
}, (function()
  package.path = pathpre
end)()

local shader = {
  path = package.path:sub(1,#package.path-5) .. "g3d.vert",
  list = {},
}

shader.shader = love.graphics.newShader(shader.path)
-- local prepared = {}
function shader.sendMat3(matrix, Shader, var)
  Shader:send(var, {
    matrix[1], matrix[2], matrix[3],
    matrix[5], matrix[6], matrix[7],
    matrix[9], matrix[10], matrix[11],
  })
end
function shader.prepare(Shader, camera)
  -- local camera = package.loaded.camera
  shader.sendMat3(camera.viewMatrix, Shader, "viewMatrix")
end

--function shader.depthBillPrepare(shader)
--[[
  local camDir, camPit = camera.getDirectionPitch()
  local cosPitch = math.cos(camPit)
  local sinPitch = math.sin(camPit)
  local ax, ay = -math.sin(camDir), math.cos(camDir)
  local camFor = {
  	ay*cosPitch,
  	-ax*cosPitch,
  	sinPitch,
  }
  local camUp = {
    ay * sinPitch,
    -ax * sinPitch,
    -cosPitch,
  }
  shader:send("cameraUp", {0,0,1})
  shader:send("cameraForward", camFor)
  shader:send("cameraPos", camera.position)
  shader:send("cameraRight", {ax,ay})
  ]]
--shader.prepare(shader,camera)
--end
table.insert(shader.list, shader.shader)
return shader

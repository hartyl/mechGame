return function(path)
  local fcurves = {Left = {}, Right = {}, Middle = {}}
  local file = love.filesystem.read(path)
  local pos = "Middle"
  local boneName = nil
  local scale = 2
  for line in file:gmatch '(.-)\n' do
    if line:find '^%u' then
      boneName = line:match "^%u +(.+)$"
      if boneName:find "Left" then
        boneName = boneName:sub(5)
        fcurves.Left[boneName] = {}
        pos = "Left"
      elseif boneName:find "Right" then
        boneName = boneName:sub(6)
        fcurves.Right[boneName] = {}
        pos = "Right"
      else
        fcurves.Middle[boneName] = {}
        pos = "Middle"
      end
    else
      local d1, d2, d3 = line:match '^(.-) (.-) (.-)$'
      if tonumber(d1) then
        --assert(fcurves[boneName], table.concat({ boneName or " ", d1, d2, d3 }, "\n"))
        assert(fcurves[pos])
        table.insert(fcurves[pos][boneName], { tonumber(d1) * scale, -tonumber(d3) * scale, tonumber(d2) * scale })
      end
    end
  end
  return fcurves
end

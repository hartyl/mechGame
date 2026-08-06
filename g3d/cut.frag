varying vec2 texCoord;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
  vec4 texcolor = Texel(tex, texCoord);
  return texcolor;
}

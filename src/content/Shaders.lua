-- Shader list

local Shaders = {
    default = love.graphics.newShader(
        "assets/shaders/simple_vertex.glsl",
        "assets/shaders/simple_pixel.glsl"
    )
}


return Shaders
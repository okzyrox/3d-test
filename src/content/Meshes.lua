-- Builtin Mesh list

--
local Mesh = require "content.Mesh"

local Meshes = {
    cube = Mesh():from_file("assets/meshes/cube.obj"),
    pyramid = Mesh():from_file("assets/meshes/pyramid.obj"),
    cone = Mesh():from_file("assets/meshes/cone.obj"),
    sphere = Mesh():from_file("assets/meshes/sphere.obj")
}


return Meshes
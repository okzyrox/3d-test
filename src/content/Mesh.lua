local fps = require "lib.fps"
local lmath = require "lib.lmath"
local wavefront = require "lib.wavefront"
local Class = require "lib.classic"

local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_rad = math.rad
local math_sqrt = math.sqrt

local MeshFormats = {
    static = {
        { "VertexPosition", "float", 3 },
        { "VertexNormal",   "float", 3 },
        { "VertexTexture",  "float", 2 }
    }
}

local Mesh = Class:extend()

function Mesh:from_file(filepath)
    local data = love.filesystem.read(filepath)

    self.data = wavefront.import(data)

    local min_x, min_y, min_z = 0, 0, 0
    local max_x, max_y, max_z = 0, 0, 0

    --Calculate boundary
    for i = 1, #self.data.vertices, 3 do
        local vx = self.data.vertices[i]
        local vy = self.data.vertices[i + 1]
        local vz = self.data.vertices[i + 2]

        min_x = math_min(vx, min_x)
        min_y = math_min(vy, min_y)
        min_z = math_min(vz, min_z)

        max_x = math_max(vx, max_x)
        max_y = math_max(vy, max_y)
        max_z = math_max(vz, max_z)
    end

    local size_x = max_x - min_x
    local size_y = max_y - min_y
    local size_z = max_z - min_z

    local middle_x = (min_x + max_x) / 2
    local middle_y = (min_y + max_y) / 2
    local middle_z = (min_z + max_z) / 2

    do
        local vertices = {}

        local vertices_ = {}

        for i = 1, #self.data.vertices, 3 do
            local vx       = self.data.vertices[i]
            local vy       = self.data.vertices[i + 1]
            local vz       = self.data.vertices[i + 2]

            vertices_[i]   = (vx - middle_x) / size_x
            vertices_[i + 1] = (vy - middle_y) / size_y
            vertices_[i + 2] = (vz - middle_z) / size_z
        end

        for i = 1, #self.data.faces, 3 do
            vertices[#vertices + 1] = {
                vertices_[(self.data.faces[i] - 1) * 3 + 1],
                vertices_[(self.data.faces[i] - 1) * 3 + 2],
                vertices_[(self.data.faces[i] - 1) * 3 + 3],
                self.data.normals[(self.data.faces[i + 1] - 1) * 3 + 1],
                self.data.normals[(self.data.faces[i + 1] - 1) * 3 + 2],
                self.data.normals[(self.data.faces[i + 1] - 1) * 3 + 3],
                self.data.textures[(self.data.faces[i + 2] - 1) * 2 + 1],
                self.data.textures[(self.data.faces[i + 2] - 1) * 2 + 2]
            }
        end

        self.drawable = love.graphics.newMesh(
            MeshFormats.static, vertices,
            "triangles", "static"
        )
    end

    do
        local faces = {}

        for i = 1, #self.data.faces, 3 do
            faces[#faces + 1] = self.data.faces[i]
        end

        self.shape = fps.shape.new(self.data.vertices, faces)
    end

    print("Mesh loaded: " .. filepath)
    print(self.drawable)
    print(self.data)
    print(self.data.vertices)
    print(self.shape)

    return self
end

return Mesh
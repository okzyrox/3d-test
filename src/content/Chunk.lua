local lmath = require "lib.lmath"
local Class = require "lib.classic"
local fps = require "lib.fps"

local Meshes = require "content.Meshes"
local Shaders = require "content.Shaders"

local Chunk = Class:extend()

function Chunk:new(id, x, y, z)
    self.id = id
    self.pos = lmath.vector3.new(x, y, z)
    self.transform = lmath.matrix4.new()
    self.render_chunk_bounds = true
    self._fixtures = {}
    self._body = fps.body.new()
    --self._body:set_collidable(true)
    print("Chunk created: " .. self.id)
    local chunk_fixtures = {
        {
            Meshes.cube,
            lmath.vector3.new(3 * 16, 3 * 64, 3 * 16),
            lmath.matrix4.new()
        }
    }

    for _, fixture in pairs(chunk_fixtures) do
        local collider = fps.collider.new()
        collider:set_shape(fixture[1].shape)
        collider:set_size(fixture[2]:unpack())
        collider:set_transform(fixture[3]:unpack())
        self._body:add_collider(collider)
        self._fixtures[collider] = fixture[1]
    end

    self.blocks = {}
    self._mat4 = lmath.matrix4.new()
    return self
end

function Chunk:add_block(block)
    self.blocks[#self.blocks + 1] = block
end

function Chunk:draw(render_chunk_bounds, render_block_bounds)
    local body = self._body
    local boundary = body.boundary

    for _, collider in ipairs(body.colliders) do
        self._mat4
            :set(unpack(body.transform))
            :multiply(collider.transform)
            :scale(
                collider.size[1],
                collider.size[2],
                collider.size[3]
            )

        Shaders.default:send("model", "row", self._mat4)
    end

    local middle_x = (boundary[1] + boundary[4]) / 2
    local middle_y = (boundary[2] + boundary[5]) / 2
    local middle_z = (boundary[3] + boundary[6]) / 2

    self._mat4
        :set()
        :set_position(middle_x, middle_y, middle_z)
        :scale(
            boundary[4] - boundary[1],
            boundary[5] - boundary[2],
            boundary[6] - boundary[3]
        )
    if render_chunk_bounds then
        love.graphics.setWireframe(true)
        love.graphics.setMeshCullMode("none")
        Shaders.default:send("model", "row", self._mat4)
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.draw(Meshes.cube.drawable)
    end

    for _, block in pairs(self.blocks) do
        block:draw(render_block_bounds)
    end
end

return Chunk
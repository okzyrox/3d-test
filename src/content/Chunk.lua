local lmath = require "lib.lmath"
local Class = require "lib.classic"
local fps = require "lib.fps"

local Meshes = require "content.Meshes"
local Shaders = require "content.Shaders"

local Vec2 = require "content.Vector2"

local Chunk = Class:extend()

function Chunk:new(id, world, x, z)
    self.id = id
    self.pos = Vec2(x, z)
    -- Starts from (0, 0, 0)
    -- goes out by 1 per chunk (x and z)
    -- so the surrounding chunks would be:
    --[[
    (1, 0, 0)
    (0, 0, 1)
    (1, 0, 1)
    (-1, 0, 0)
    (-1, 0, 1)
    (0, 0, -1)
    (1, 0, -1)
    (-1, 0, -1)
    ]]
    self.transform = lmath.matrix4.new()
    self.render_chunk_bounds = true
    self._fixtures = setmetatable({}, { __mode = "k" })

    self._world = world
    self._body = fps.body.new()
    self._body:set_position(self.pos.x, 32, self.pos.z)
    self._body:set_collidable(false)
    print("Chunk created: " .. self.id)
    local chunk_fixtures = {
        {
            Meshes.cube,
            lmath.vector3.new(4.35 * 16, 3.5 * 64, 4.35 * 16),
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
    if self._world ~= nil then
        local blockLocalX = block.pos.x / 2.5 - (self.pos.x + 16)
        local blockLocalY = block.pos.y / 2.5  - 32
        local blockLocalZ = block.pos.z / 2.5 - (self.pos.z + 16)
        blockLocalX = blockLocalX * 2.5
        blockLocalY = blockLocalY * 2.5
        blockLocalZ = blockLocalZ * 2.5

        block:set_position(blockLocalX, blockLocalY, blockLocalZ)
        self._world:add_body(block._body)
    end
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

function Chunk:update()
    for _, block in pairs(self.blocks) do
        block:update()
    end
end

return Chunk
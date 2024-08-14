local lmath = require "lib.lmath"
local Class = require "lib.classic"
local fps = require "lib.fps"

local Meshes = require "content.Meshes"
local Shaders = require "content.Shaders"

local Chunk = Class:extend()

function Chunk:new(id, world, x, z)
    print("Creating chunk: " .. id .. " at " .. x .. ", " .. z)
    self.id = id
    self.pos = lmath.vector2.new(x, z)
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

    self._body = fps.body.new()
    self._body:set_position(self.pos.x, 0, self.pos.y)
    self._body:set_collidable(false)
    self._world = world
    
    print("Chunk created: " .. self.id)
    local chunk_fixtures = {
        {
            Meshes.cube,
            lmath.vector3.new(1 * 16, 1 * 64, 1 * 16),
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
    block:set_position(block.pos.x + self.pos.x * 17 , block.pos.y, block.pos.z + self.pos.y * 17)
    self.blocks[#self.blocks + 1] = block
    if self._world ~= nil then
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
        block:draw(block.pos.x + self.pos.x * 16, block.pos.y, block.pos.z + self.pos.y * 16, render_block_bounds)
    end
end

function Chunk:update()
    for _, block in pairs(self.blocks) do
        block:update()
    end
end

function Chunk:destroy()
    for _, block in pairs(self.blocks) do
        block:destroy()
    end
    self.blocks = nil

    if self._body then
        if self._world then
            self._world:remove_body(self._body)
        end
        self._body = nil
    end

    for collider, _ in pairs(self._fixtures) do
        collider = nil
    end
    self._fixtures = nil

    self.transform = nil
    self.pos = nil
    self._mat4 = nil
    if self._world then
        self._world = nil
    end
end

return Chunk
local fps = require "lib.fps"
local lmath = require "lib.lmath"
local Class = require "lib.classic"
local Json = require "lib.json"
local utils= require "content.utils"

local Meshes = require "content.Meshes"
local Shaders = require "content.Shaders"

local Game = Class:extend()

function Game:new()
    self.render_wireframe = false
    self.render_bounding_box = false
    self.step_physics = false

    self._buffer = {
        love.graphics.newCanvas(
            love.graphics.getWidth(),
            love.graphics.getHeight(),
            { format = "normal" }
        ),
        depth = true
    }
    self._world = fps.world.new()
    self._world:add_solver(fps.solvers.rigid)
    self._world:set_gravity(0, -50, 0)
    self._objects = {}
    self.chunks = {}
    --self.blocks = {}
    self._mat4 = lmath.matrix4.new()
    return self
end

function Game:get_world()
    return self._world
end

function Game:add_body(body)
    self._world:add_body(body)
end

function Game:add_block(block)
    self.chunks[1]:add_block(block)
end

function Game:add_chunk(new_chunk)
    for _, chunk in ipairs(self.chunks) do
        if chunk.pos.x == new_chunk.pos.x and chunk.pos.y == new_chunk.pos.y then
            print("Chunk already exists at " .. new_chunk.pos.x .. ", " .. new_chunk.pos.y)
            return false
        end
    end
    self.chunks[#self.chunks + 1] = new_chunk
    self:add_body(new_chunk._body)
end

function Game:get_object_count()
    return #self._objects
end

function Game:get_chunk_count()
    return #self.chunks
end

function Game:get_block_count()
    local count = 0
    for _, chunk in ipairs(self.chunks) do
        for _, block in ipairs(chunk.blocks) do
            count = count + 1
        end
    end
    return count
end

function Game:new_object(fixtures, transform, color, static)
    if static == nil then
        static = true
    end
    local object = {}
    object.fixtures = {}
    object.body = fps.body.new()
    object.color = color or lmath.color3.new(1, 1, 1)

    object.body:set_transform(transform:unpack())
    object.body:set_static(static)

    for _, fixture in pairs(fixtures) do
        local collider = fps.collider.new()
        collider:set_shape(fixture[1].shape)
        collider:set_size(fixture[2]:unpack())
        collider:set_transform(fixture[3]:unpack())
        object.body:add_collider(collider)

        object.fixtures[collider] = fixture[1]
    end

    self.static = static

    self:add_body(object.body)
    self._objects[object.body] = object
    return object
end

function Game:get_objects()
    return self._objects
end

function Game:clear_objects(include_static)
    if include_static == true then
        self._objects = {}
    else
        local objects = self:get_objects()
        for _, object in pairs(objects) do
            if object.static == false then
                self._objects[object.body] = nil
            end
        end
    end
end

function Game:draw(camera, camera_projection)
    self._mat4:set(camera:unpack()):inverse()

    love.graphics.push("all")
    love.graphics.setCanvas(self._buffer)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setShader(Shaders.default)
    Shaders.default:send("projection", "row", camera_projection)
    Shaders.default:send("view", "row", self._mat4)

    for _, object in pairs(self._objects) do
        if self.render_wireframe then
            love.graphics.setWireframe(true)
            love.graphics.setMeshCullMode("none")
        else
            love.graphics.setWireframe(false)
            love.graphics.setMeshCullMode("front")
        end

        local body = object.body
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

            love.graphics.setColor(object.color.r, object.color.g, object.color.b, 1)

            love.graphics.draw(object.fixtures[collider].drawable)
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

        if self.render_bounding_box then
            love.graphics.setWireframe(true)
            love.graphics.setMeshCullMode("none")
            Shaders.default:send("model", "row", self._mat4)
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.draw(Meshes.cube.drawable)
        end
    end
    for _, chunk in pairs(self.chunks) do
        if self.render_wireframe then
            love.graphics.setWireframe(true)
            love.graphics.setMeshCullMode("none")
        else
            love.graphics.setWireframe(false)
            love.graphics.setMeshCullMode("front")
        end
        local lookx, looky, lookz = camera_projection:get_look()
        local look = {
            x = lookx,
            y = looky,
            z = lookz
        }
        chunk:draw(look, self.render_bounding_box, self.render_bounding_box)
    end

    love.graphics.pop()
    love.graphics.draw(
        self._buffer[1],
        0, self._buffer[1]:getHeight(),
        0, 1, -1
    )
end

function Game:update(dt)
    if not self.step_physics then
        self._world:step(math.min(dt, 1 / 60))
    end
end

function Game:load()
    local json_data = love.filesystem.read("save.json")
    local save_data = Json.decode(json_data)
    self._objects = {}
    self._world:clear_bodies()
    for _, data in ipairs(save_data) do
        self:new_object(
            {
                {
                    Meshes.cube,
                    lmath.vector3.new(data.colliders[1].size.x, data.colliders[1].size.y, data.colliders[1].size.z),
                    lmath.matrix4.new()
                }
            }, 
            lmath.matrix4.new():set_position(data.pos.x, data.pos.y, data.pos.z), 
            lmath.color3.new(data.col.r, data.col.g, data.col.b), 
            data.is_static
        )
    end
    collectgarbage()
end
function Game:save()
    local save_data = {}
    for _, object in pairs(self._objects) do
        local pos_x, pos_y, pos_z = object.body:get_position()
        local col_r, col_g, col_b = object.color:unpack()
        local data ={
            ["pos"] = {["x"] = pos_x, ["y"] = pos_y, ["z"] = pos_z},
            ["col"] = {["r"] = col_r, ["g"] = col_g, ["b"] = col_b},
            ["is_static"] = object.body:get_static(),
            ["colliders"] = {}
        }
        local i = 1
        for _, collider in ipairs(object.body.colliders) do
            data["colliders"][i] = {
                ["size"] = {
                    ["x"] = collider.size[1],
                    ["y"] = collider.size[2],
                    ["z"] = collider.size[3],
                }
            }
            i = i + 1
        end
        table.insert(save_data, data)
    end
    local json_data = Json.encode(save_data)
    love.filesystem.write("save.json", json_data)
    collectgarbage()
end

return Game
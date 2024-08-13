local fps = require "lib.fps"
local lmath = require "lib.lmath"
local Class = require "lib.classic"

local Meshes = require "content.Meshes"

local Game = Class:extend()

function Game:new()
    self.shaders = {
        default = love.graphics.newShader(
            "assets/shaders/simple_vertex.glsl",
            "assets/shaders/simple_pixel.glsl"
        )
    }
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
    self._mat4 = lmath.matrix4.new()
    return self
end

function Game:get_world()
    return self._world
end

function Game:add_body(body)
    self._world:add_body(body)
end

function Game:add_shader(id, shader)
    self.shaders[id] = shader
end

function Game:get_object_count()
    return #self._objects
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
    love.graphics.setShader(self.shaders.default)
    self.shaders.default:send("projection", "row", camera_projection)
    self.shaders.default:send("view", "row", self._mat4)

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

            self.shaders.default:send("model", "row", self._mat4)

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
            self.shaders.default:send("model", "row", self._mat4)
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.draw(Meshes.cube.drawable)
        end
    end
    love.graphics.pop()
    love.graphics.draw(
        self._buffer[1],
        0, self._buffer[1]:getHeight(),
        0, 1, -1
    )
end

return Game
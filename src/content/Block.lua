local lmath = require "lib.lmath"
local Class = require "lib.classic"
local fps = require "lib.fps"

local Meshes = require "content.Meshes"
local Shaders = require "content.Shaders"

local Block = Class:extend()

function Block:new(id, world, x, y, z, falling)
    if falling == nil then
        falling = false
    end
    self.id = id
    self.pos = lmath.vector3.new(x, y, z) -- Relative chunk coordinates
    self.transform = lmath.matrix4.new()
    self.color = lmath.color3.new(1, 1, 1)
    self.falling_block = falling

    self._world = world
    self._body = fps.body.new()
    
    self._body:set_position(self.pos.x, self.pos.y, self.pos.z)

    self._fixtures = {}

    local block_fixtures = {
        {
            Meshes.cube,
            lmath.vector3.new(1, 1, 1),
            lmath.matrix4.new()
        }
    }

    for _, fixture in pairs(block_fixtures) do
        local collider = fps.collider.new()
        collider:set_shape(fixture[1].shape)
        collider:set_size(fixture[2]:unpack())
        collider:set_transform(fixture[3]:unpack())
        self._body:add_collider(collider)

        self._fixtures[collider] = fixture[1]
    end
    
    self._mat4 = lmath.matrix4.new()

    return self
end

function Block:set_color(r, g, b)
    self.color = lmath.color3.new(r, g, b)
end

function Block:update(dt)
    if self.falling_block == true then
        self:fall(dt)

        if self.pos.y < -10 then
            self:set_position(self.pos.x, 20, self.pos.z)
        end
    end
end

function Block:set_position(x, y, z)
    self.pos.x = x
    self.pos.y = y
    self.pos.z = z
    self._body:set_position(x, y, z)
end

function Block:fall(dt)
    self:set_position(self.pos.x, self.pos.y - 4 * dt, self.pos.z)
end

-- lol
-- we pass camera look, the WHOLE chunk, and the face
-- well it kinda works since with the testing values it worked for culling a ton of cubes (all sides)
-- but still has some jank
-- TODO: do later
function Block:is_face_visible(camera_look_vec, chunk, face_normal, x, y, z)
    local neighborPos = lmath.vector3.new(x, y, z):add(face_normal)
    if chunk:find_block_at(neighborPos.x, neighborPos.y, neighborPos.z) then
        return false
    end
    if face_normal:get_dot(camera_look_vec) < 0 then
        return true
    end

    return false
end

function Block:draw(camera_look_vec, chunk, x, y, z, render_bounding_box)
    local body = self._body
    local boundary = body.boundary

    -- Define the normals for each face of a cube
    local faces = {
        { normal = lmath.vector3.new( 1, 0, 0), transform = lmath.matrix4.new():translate(0.5, 0, 0) }, -- Right face
        { normal = lmath.vector3.new(-1, 0, 0), transform = lmath.matrix4.new():translate(-0.5, 0, 0) }, -- Left face
        { normal = lmath.vector3.new( 0, 1, 0), transform = lmath.matrix4.new():translate(0, 0.5, 0) }, -- Top face
        { normal = lmath.vector3.new( 0,-1, 0), transform = lmath.matrix4.new():translate(0, -0.5, 0) }, -- Bottom face
        { normal = lmath.vector3.new( 0, 0, 1), transform = lmath.matrix4.new():translate(0, 0, 0.5) }, -- Front face
        { normal = lmath.vector3.new( 0, 0,-1), transform = lmath.matrix4.new():translate(0, 0, -0.5) }, -- Back face
    }

    for _, face in ipairs(faces) do
        if self:is_face_visible(camera_look_vec, chunk, face.normal, x, y, z) then
            for _, collider in ipairs(body.colliders) do
                self._mat4
                    :set(unpack(body.transform))
                    :multiply(face.transform)
                    :multiply(collider.transform)
                    :scale(
                        collider.size[1],
                        collider.size[2],
                        collider.size[3]
                    )

                Shaders.default:send("model", "row", self._mat4)

                love.graphics.setColor(self.color.r, self.color.g, self.color.b, 1)
                love.graphics.draw(self._fixtures[collider].drawable)
            end
        end
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
    if render_bounding_box then
        love.graphics.setWireframe(true)
        love.graphics.setMeshCullMode("none")
        Shaders.default:send("model", "row", self._mat4)
        love.graphics.setColor(self.color.r, self.color.g, self.color.b, 1)
        love.graphics.draw(Meshes.cube.drawable)
    end
end

function Block:destroy()
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
    self.color = nil
    self.pos = nil
end
return Block
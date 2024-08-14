local fps = require "lib.fps"
local lmath = require "lib.lmath"
local Class = require "lib.classic"

local Camera = Class:extend()

function Camera:new(id, posx, posy, posz)
    if posx == nil then
        posx = 0
    end
    if posy == nil then
        posy = 0
    end
    if posz == nil then
        posz = 0
    end
    local cam = lmath.matrix4.new():set_position(posx, posy, posz)
    self.id = id
    self.camera = cam
    self.keymap = {
        w = lmath.vector3.new(0, 0, -1),
        s = lmath.vector3.new(0, 0, 1),
        a = lmath.vector3.new(-1, 0, 0),
        d = lmath.vector3.new(1, 0, 0),
        e = lmath.vector3.new(0, 1, 0),
        q = lmath.vector3.new(0, -1, 0)
    }
    self.view = lmath.matrix4.new():set(cam:unpack())
    self.move_dir = lmath.vector3.new()
    self.look_angle = lmath.vector2.new()
    self.projection = lmath.matrix4.new():set_perspective(
        75,
        love.graphics.getWidth() / love.graphics.getHeight(),
        0.1, 1000
    )
    return self
end

function Camera:get_look()
    return self.camera:get_look()
end

function Camera:step(dt)
    self.move_dir:set()
    for key, vector in pairs(self.keymap) do
        if love.keyboard.isDown(key) then
            self.move_dir:add(vector)
        end
    end
    self.move_dir = self.move_dir:normalize():multiply(dt * (love.keyboard.isDown("lshift") and 40 or 20))
    if self.move_dir:get_magnitude() ~= 0 then
        self.view:transform(self.move_dir:unpack())
    end
    self.camera:lerp(self.view, dt / 0.1)
end

function Camera:input(dx, dy)
    if love.mouse.isDown(1, 2) then
        self.look_angle.x = lmath.clamp(
            self.look_angle.x - math.rad(dy * 0.4),
            math.rad(-89), math.rad(89)
        )
        self.look_angle.y = self.look_angle.y - math.rad(dx * 0.4)
        self.view:set_euler(0, self.look_angle.y, 0)
            :rotate_euler(self.look_angle.x, 0, 0)
    end
end

return Camera
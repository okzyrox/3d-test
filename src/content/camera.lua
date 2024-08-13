local fps = require "lib.fps"
local lmath = require "lib.lmath"
local Class = require "lib.classic"

local Camera = Class:extend()

function Camera:new()
    self._camera = lmath.matrix4.new()
    self._keymap = {
        w = lmath.vector3.new(0, 0, -1),
        s = lmath.vector3.new(0, 0, 1),
        a = lmath.vector3.new(-1, 0, 0),
        d = lmath.vector3.new(1, 0, 0),
        e = lmath.vector3.new(0, 1, 0),
        q = lmath.vector3.new(0, -1, 0)
    }
    self._view = lmath.matrix4.new():set(self._camera:unpack())
    self._move_dir = lmath.vector3.new()
    self._look_angle = lmath.vector2.new()
    self._projection = lmath.matrix4.new():set_perspective(
        75,
        love.graphics.getWidth() / love.graphics.getHeight(),
        0.1, 1000
    )
    return self
end

function Camera:get_look()
    return self._camera:get_look()
end

function Camera:get_projection()
    return self._projection
end

function Camera:step(dt)
    self._move_dir:set()
    for key, vector in pairs(self._keymap) do
        if love.keyboard.isDown(key) then
            self._move_dir:add(vector)
        end
    end
    self._move_dir = self._move_dir:normalize():multiply(dt * (love.keyboard.isDown("lshift") and 40 or 20))
    if self._move_dir:get_magnitude() ~= 0 then
        self._view:transform(self._move_dir:unpack())
    end
    self._camera:lerp(self._view, dt / 0.1)
end

function Camera:input(dx, dy)
    if love.mouse.isDown(1, 2) then
        self._look_angle.x = lmath.clamp(
            self._look_angle.x - math.rad(dy * 0.4),
            math.rad(-89), math.rad(89)
        )
        self._look_angle.y = self._look_angle.y - math.rad(dx * 0.4)
        self._view:set_euler(0, self._look_angle.y, 0)
            :rotate_euler(self._look_angle.x, 0, 0)
    end
end

return Camera
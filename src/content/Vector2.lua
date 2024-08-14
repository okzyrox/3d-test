local lmath = require "lib.lmath"
local Class = require "lib.classic"

local sqrt = math.sqrt

local Vector2 = Class:extend()

function Vector2:new(x, y)
    if x == nil then
        x = 0
    end
    if y == nil then
        y = 0
    end
    self.x = x
    self.y = y

    return self
end

function Vector2:unpack()
    return self.x, self.y
end

function Vector2:set(x, y)
    self.x = x
    self.y = y
end

function Vector2:__tostring()
    return "(" .. self.x .. ", " .. self.y .. ")"
end

return Vector2
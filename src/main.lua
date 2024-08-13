local lmath = require "lib.lmath"
local wavefront = require "lib.wavefront"
local fps = require "lib.fps"
local Meshes = require "content.Meshes"
-- Game

local Game = require "content.game"
-------------------------------------------------------------------------------
-- Start

local game = Game:new()
local world = game:get_world()


function love.load()
    game:new_object(
        {
            {
                Meshes.cube,
                lmath.vector3.new(30, 1, 30),
                lmath.matrix4.new()
            }
        },
        lmath.matrix4.new(),
        lmath.color3.new(1, 1, 1)
    )

    game:new_object(
        {
            {
                Meshes.cube,
                lmath.vector3.new(30, 10, 1),
                lmath.matrix4.new()
            }
        },
        lmath.matrix4.new():set_position(0, 5, -15),
        lmath.color3.new(1, 1, 1)
    )

    game:new_object(
        {
            {
                Meshes.cube,
                lmath.vector3.new(30, 10, 1),
                lmath.matrix4.new()
            }
        },
        lmath.matrix4.new():set_position(0, 5, 15),
        lmath.color3.new(1, 1, 1)
    )

    game:new_object(
        {
            {
                Meshes.cube,
                lmath.vector3.new(1, 10, 30),
                lmath.matrix4.new()
            }
        },
        lmath.matrix4.new():set_position(-15, 5, 0),
        lmath.color3.new(1, 1, 1)
    )

    game:new_object(
        {
            {
                Meshes.cube,
                lmath.vector3.new(1, 10, 30),
                lmath.matrix4.new()
            }
        },
        lmath.matrix4.new():set_position(15, 5, 0),
        lmath.color3.new(1, 1, 1)
    )
end

local static_creation = false

function love.draw(dt)
    game:draw()

    love.graphics.print(
        (
            "FPS: %d\n" ..
            "Mem: %0.2f mb\n" ..
            "Bodies: %d\n" ..
            "Wireframe: %s\n" ..
            "Show Bounding Box: %s\n" ..
            "Physics: %s\n" ..
            "StaticCreation: %s "
        ):format(
            love.timer.getFPS(),
            collectgarbage("count") / 1024,
            #world.bodies,
            tostring(game.render_wireframe),
            tostring(game.render_bounding_box),
            game.step_physics and "Step" or "Realtime",
            tostring(static_creation)
        ),
        5, 5
    )
end

local tick = love.timer.getTime()
local scale = 1

local pull_origin = lmath.matrix4.new()
local pull_force  = 50

function love.update(dt)
    game:step_camera(dt)

    pull_origin
        :set(game:get_true_camera():unpack())
        :transform(0, 0, -15)

    local pull_x, pull_y, pull_z = pull_origin:get_position()

    if love.keyboard.isDown("r") then
        local objects = game:get_objects()
        for _, object in pairs(objects) do
            if not object.body:get_static() then
                local x, y, z = object.body:get_position()

                local mass = object.body:get_mass()

                object.body:apply_force(
                    (pull_x - x) * mass * pull_force,
                    (pull_y - y) * mass * pull_force,
                    (pull_z - z) * mass * pull_force
                )

                --Dampen the velocity so they stop swooshing around
                object.body.velocity[1] = object.body.velocity[1] * 0.99
                object.body.velocity[2] = object.body.velocity[2] * 0.99
                object.body.velocity[3] = object.body.velocity[3] * 0.99

                object.body.angular_velocity[1] = object.body.angular_velocity[1] * 0.99
                object.body.angular_velocity[2] = object.body.angular_velocity[2] * 0.99
                object.body.angular_velocity[3] = object.body.angular_velocity[3] * 0.99
            end
        end
    end

    if not game.step_physics then
        world:step(math.min(dt, 1 / 60))
    end
end

function love.mousemoved(x, y, dx, dy)
    game:input_camera(dx, dy)
end

function love.keypressed(key)
    if key == "f" then
        local lx, ly, lz = game:camera_get_look()

        local mesh = math.random(1, 4)

        local bullet = game:new_object(
            {
                {
                    (mesh == 1 and Meshes.cube) or
                    (mesh == 2 and Meshes.pyramid) or
                    (mesh == 3 and Meshes.cone) or
                    (mesh == 4 and Meshes.sphere),
                    lmath.vector3.new(3, 3, 3),
                    lmath.matrix4.new()
                }
            },
            lmath.matrix4.new():set(game:get_true_camera():unpack()):transform(0, 0, -6),
            lmath.color3.new(
                math.random(0, 255) / 255,
                math.random(0, 255) / 255,
                math.random(0, 255) / 255
            ),
            static_creation
        )

        --bullet.body:set_static(false)
        bullet.body:set_velocity(
            lx * 20, ly * 20, lz * 20
        )
    elseif key == "1" then
        game.render_wireframe = not game.render_wireframe
    elseif key == "2" then
        game.render_bounding_box = not game.render_bounding_box
    elseif key == "3" then
        game.step_physics = not game.step_physics
    elseif key == "t" and game.step_physics then
        world:step(1 / 60)
    elseif key == "4" then
        static_creation = not static_creation
    elseif key == "z" then
        game:clear_objects(false)
    elseif key == "p" then
        game:clear_objects(true)
    end
end

collectgarbage()

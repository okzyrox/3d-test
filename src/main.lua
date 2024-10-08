local lmath = require "lib.lmath"
local lang_lib = require "lib.language"
local wavefront = require "lib.wavefront"
local fps = require "lib.fps"
-- Game

local Languages = require "content.Languages"
local Game = require "content.Game"
local Meshes = require "content.Meshes"
local Camera = require "content.Camera"
local Block = require "content.Block"
local Chunk = require "content.Chunk"
local Utils = require "content.utils"
-------------------------------------------------------------------------------
-- Start

local MainGame = Game:new()
local world = MainGame:get_world()
local MainCamera = Camera("first_cam", 0, 5, 0)
local SecondCamera = Camera("second_cam", 0, 5, 0)

local CurrentCamera = MainCamera

local new_block

local function new_chunk()
    local chunk = Chunk("chunk" .. tostring(math.random(0, 255)), world, math.random(-1, 1), math.random(-1, 1))
    --[[
    chunk:add_block(
        Block("test", 0, 0, 0, false)
    )
    chunk:add_block(
        Block("test2", 16, 0, 16, false)
    )]]
    for i = 0, 16 do
        for j = 0, 0 do
            for k = 0, 16 do
                --if i == 0 or i == 16 or j == 0 or j == 16 or k == 0 or k == 16 then
                -- 2.5x is the amount needed for equal spacing
                local block = Block("test", world, i, j, k, false)
                if i == 16 or k == 16 then
                    block:set_color(1, 0, 0)
                elseif i == 0 or k == 0 then
                    block:set_color(1, 0, 0)
                else
                    block:set_color(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255)
                end
                chunk:add_block(
                    block
                )
            end
        end
    end

    return chunk
end

function love.load()
    lang_lib.loadLanguage("en", Languages.english)
    lang_lib.setLanguage("en")
   -- Utils.tableprint(lang_lib.getLocalizationData())
    
    MainGame:add_chunk(
        new_chunk()
    )
end

local static_creation = false

function love.draw(dt)
    MainGame:draw(CurrentCamera.camera, CurrentCamera.projection)
    local cam_pos = CurrentCamera:get_position()
    love.graphics.print(
        (
            "--- Performance ---\n" ..
            "FPS: %d \n" ..
            "Mem: %0.2f mb \n" ..
            "Bodies: %d \n" ..
            "Wireframe: %s \n" ..
            "Show Bounding Box: %s \n" ..
            "-- Physics -- \n" ..
            "Physics: %s \n" ..
            "Static Creation: %s \n" ..
            "--- Camera --- \n" ..
            "Current Camera: %s \n" ..
            "Camera shift-locked: %s \n" ..
            "Camera pos: (%d, %d, %d) \n" ..
            "--- World --- \n" ..
            "Chunks: %d \n" ..
            "Blocks: %d \n"  .. 
            "--- Misc --- \n" ..
            "Current Language: %s"
        ):format(
            love.timer.getFPS(),
            collectgarbage("count") / 1024,
            #world.bodies,
            tostring(MainGame.render_wireframe),
            tostring(MainGame.render_bounding_box),
            MainGame.step_physics and "Step" or "Realtime",
            tostring(static_creation),
            CurrentCamera.id,
            tostring(CurrentCamera.mouse_locked),
            cam_pos[1],
            cam_pos[2],
            cam_pos[3],
            MainGame:get_chunk_count(),
            MainGame:get_block_count(),
            lang_lib.getLanguage()
        ),
        5, 5
    )
end

local pull_origin = lmath.matrix4.new()
local pull_force  = 50

function love.update(dt)
    CurrentCamera:step(dt)

    pull_origin
        :set(CurrentCamera.camera:unpack())
        :transform(0, 0, -15)

    local pull_x, pull_y, pull_z = pull_origin:get_position()

    if love.keyboard.isDown("r") then
        local objects = MainGame:get_objects()
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

    MainGame:update(dt)
    
end

function love.mousemoved(x, y, dx, dy)
    CurrentCamera:input(dx, dy)
end

function love.keypressed(key)
    if key == "f" then
        local lx, ly, lz = CurrentCamera:get_look()

        local mesh = math.random(1, 4)

        local bullet = MainGame:new_object(
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
            lmath.matrix4.new():set(CurrentCamera.camera:unpack()):transform(0, 0, -6),
            lmath.color3.new(
                math.random(0, 255) / 255,
                math.random(0, 255) / 255,
                math.random(0, 255) / 255
            ),
            static_creation
        )
        bullet.body:set_velocity(
            lx * 20, ly * 20, lz * 20
        )
    elseif key == "c" then
        local chunk = new_chunk()

        if MainGame:add_chunk(chunk) == false then
            chunk:destroy()
        end
    elseif key == "b" then
        local fall = math.random(0, 1) == 1

        local posx, posy, posz = math.random(-16, 16), 0, math.random(-16, 16)

        MainGame:add_block(Block("a", posx, posy, posz, fall))
    elseif key == "1" then
        MainGame.render_wireframe = not MainGame.render_wireframe
    elseif key == "2" then
        MainGame.render_bounding_box = not MainGame.render_bounding_box
    elseif key == "3" then
        MainGame.step_physics = not MainGame.step_physics
    elseif key == "t" and MainGame.step_physics then
        world:step(1 / 60)
    elseif key == "4" then
        static_creation = not static_creation
    elseif key == "z" then
        MainGame:clear_objects(false)
    elseif key == "p" then
        MainGame:clear_objects(true)
    elseif key == "5" then
        CurrentCamera = SecondCamera
    elseif key == "6" then
        CurrentCamera = MainCamera
    elseif key == "j" then
        lang_lib.setLanguage("en")
    elseif love.keyboard.isDown("lctrl") and key == "s" then
        MainGame:save()
    elseif love.keyboard.isDown("lctrl") and key == "l" then
        MainGame:load()
    elseif key == "lshift" or key == "rshift" then
        CurrentCamera:set_mouse_locked(not CurrentCamera.mouse_locked)
    end

    if key == "escape" then
        love.event.quit()
    end
end

collectgarbage()

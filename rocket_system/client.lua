local QBCore = exports['qb-core']:GetCoreObject()

local Pads = {}
local PadEntities = {}
local ActiveRockets = {}

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    return true
end


local function resolveModel(primary, fallbacks)
    if loadModel(primary) then
        return primary
    end

    for _, model in ipairs(fallbacks or {}) do
        if loadModel(model) then
            return model
        end
    end

    return nil
end

local function loadPtfx(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
end


local function openMenuCompat(entries)
    local rc2State = GetResourceState('Rc2menu')
    if rc2State == 'started' then
        local ok = pcall(function()
            exports['Rc2menu']:openMenu(entries)
        end)
        if ok then
            return true
        end

        ok = pcall(function()
            exports['Rc2menu']:OpenMenu(entries)
        end)
        if ok then
            return true
        end
    end

    local qbState = GetResourceState('qb-menu')
    if qbState == 'started' then
        local ok = pcall(function()
            exports['qb-menu']:openMenu(entries)
        end)
        if ok then
            return true
        end
    end

    TriggerEvent('QBCore:Notify', 'No supported menu resource found (Rc2menu/qb-menu).', 'error')
    return false
end

local function spawnPadEntities(pad)
    if PadEntities[pad.id] then
        return
    end

    local baseModel = resolveModel(Config.Models.base, Config.ModelFallbacks.base)
    local armModel = resolveModel(Config.Models.arm, Config.ModelFallbacks.arm)

    if not baseModel or not armModel then
        QBCore.Functions.Notify('Pad models failed to load. Check prop names.', 'error')
        return
    end

    local base = CreateObject(baseModel, pad.coords.x, pad.coords.y, pad.coords.z, false, false, false)
    SetEntityHeading(base, pad.heading)
    FreezeEntityPosition(base, true)

    local arm = CreateObject(armModel, pad.coords.x, pad.coords.y, pad.coords.z + 0.75, false, false, false)
    SetEntityHeading(arm, pad.heading)
    AttachEntityToEntity(arm, base, 0, 0.0, 0.2, 0.55, -pad.armAngle, 0.0, 0.0, false, false, false, false, 2, true)

    PadEntities[pad.id] = {
        base = base,
        arm = arm
    }

    exports['qb-target']:AddTargetEntity(base, {
        options = {
            {
                icon = 'fas fa-rocket',
                label = _L('menu_title'),
                action = function()
                    TriggerEvent('rocket_system:client:openPadMenu', pad.id)
                end
            }
        },
        distance = 2.5
    })
end

local function clearPadEntities(id)
    local entities = PadEntities[id]
    if not entities then return end

    exports['qb-target']:RemoveTargetEntity(entities.base)
    DeleteEntity(entities.arm)
    DeleteEntity(entities.base)
    PadEntities[id] = nil
end

local function refreshPads(newPads)
    for id in pairs(PadEntities) do
        if not newPads[id] then
            clearPadEntities(id)
        end
    end

    Pads = newPads

    for _, pad in pairs(Pads) do
        if PadEntities[pad.id] then
            local arm = PadEntities[pad.id].arm
            if DoesEntityExist(arm) then
                DetachEntity(arm, false, true)
                AttachEntityToEntity(arm, PadEntities[pad.id].base, 0, 0.0, 0.2, 0.55, -pad.armAngle, 0.0, 0.0, false, false, false, false, 2, true)
            end
        else
            spawnPadEntities(pad)
        end
    end
end

local function playLaunchEffects(origin)
    loadPtfx('core')
    UseParticleFxAssetNextCall('core')
    StartParticleFxLoopedAtCoord('exp_grd_burst_fire', origin.x, origin.y, origin.z, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
    UseParticleFxAssetNextCall('core')
    StartParticleFxLoopedAtCoord('sparkles_window', origin.x, origin.y, origin.z, 0.0, 0.0, 0.0, 1.8, false, false, false, false)

    PlaySoundFromCoord(-1, 'FLIGHT_LAUNCH', origin.x, origin.y, origin.z, 'MP5_SOUNDS', true, 30, false)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.35)
end

local function applyShockwave(center)
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local dist = #(playerPos - center)

    if dist <= Config.Explosion.ShockwaveRadius then
        local force = (Config.Explosion.ShockwaveRadius - dist) / Config.Explosion.ShockwaveRadius
        local dir = (playerPos - center)
        if #(dir) > 0.01 then
            dir = dir / #(dir)
            SetEntityVelocity(playerPed, dir.x * force * 18.0, dir.y * force * 18.0, force * 8.0)
        end
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.2 * force)
        AnimpostfxPlay('Rampage', 500, false)
        Wait(200)
        AnimpostfxStop('Rampage')
    end
end

local function createMegaExplosion(pos)
    loadPtfx('core')

    AddExplosion(pos.x, pos.y, pos.z, 29, Config.Explosion.MaxScale * 2.0, true, false, Config.Rocket.DamageRadius)
    AddExplosion(pos.x, pos.y, pos.z + 4.0, 4, Config.Explosion.MaxScale, true, false, Config.Rocket.ExplosionRadius)

    for i = 1, 8 do
        local offset = vec3(math.random(-16, 16) + 0.0, math.random(-16, 16) + 0.0, math.random(0, 6) + 0.0)
        AddExplosion(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, 2, Config.Explosion.MaxScale * 0.6, true, false, Config.Rocket.DamageRadius)
    end

    for i = 1, Config.Explosion.FireParticles do
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('fire_petrol_tank', pos.x + math.random(-3, 3), pos.y + math.random(-3, 3), pos.z + math.random(0, 5), 0.0, 0.0, 0.0, 2.4, false, false, false)
    end

    local smokeFx = {}
    for i = 1, Config.Explosion.SmokeParticles do
        UseParticleFxAssetNextCall('core')
        smokeFx[#smokeFx + 1] = StartParticleFxLoopedAtCoord('exp_grd_burst_smoke', pos.x + math.random(-4, 4), pos.y + math.random(-4, 4), pos.z, 0.0, 0.0, 0.0, 2.1, false, false, false, false)
    end

    for i = 1, Config.Explosion.DebrisCount do
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('ent_brk_wood_chunks', pos.x + math.random(-3, 3), pos.y + math.random(-3, 3), pos.z + math.random(1, 4), math.random(-30, 30) + 0.0, math.random(-30, 30) + 0.0, math.random(0, 360) + 0.0, 1.5, false, false, false)
    end

    StartScriptFire(pos.x, pos.y, pos.z, Config.Rocket.ExplosionRadius, true)
    PlaySoundFromCoord(-1, 'EXPLOSION_HEAVY', pos.x, pos.y, pos.z, 'MP5_SOUNDS', true, 30, false)
    PlaySoundFrontend(-1, 'BELL_END', 'HUD_MINI_GAME_SOUNDSET', true)
    PlaySoundFromCoord(-1, 'BULLDOZER_CRASH', pos.x, pos.y, pos.z, 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true, 30, false)

    applyShockwave(pos)
    AnimpostfxPlay('FocusIn', 300, false)
    Wait(300)
    AnimpostfxStop('FocusIn')

    SetTimeout(Config.Explosion.SmokeDuration, function()
        for _, fx in ipairs(smokeFx) do
            StopParticleFxLooped(fx, 0)
        end
    end)
end

local function launchRocket(pad)
    local rocketModel = resolveModel(Config.Models.launcher, Config.ModelFallbacks.launcher)
    if not rocketModel then
        QBCore.Functions.Notify('Rocket model failed to load.', 'error')
        return
    end

    local headingRad = math.rad(pad.heading)
    local angleRad = math.rad(pad.armAngle)

    local ox, oy, oz = Config.Fire.LaunchOffset.x, Config.Fire.LaunchOffset.y, Config.Fire.LaunchOffset.z
    local origin = vec3(
        pad.coords.x + (math.cos(headingRad) * oy) - (math.sin(headingRad) * ox),
        pad.coords.y + (math.sin(headingRad) * oy) + (math.cos(headingRad) * ox),
        pad.coords.z + oz
    )

    local rocket = CreateObject(rocketModel, origin.x, origin.y, origin.z, true, true, false)
    SetEntityCollision(rocket, false, false)
    SetEntityDynamic(rocket, false)

    local speed = Config.Rocket.Speed
    local vx = math.cos(headingRad) * speed * 0.1
    local vy = math.sin(headingRad) * speed * 0.1
    local vz = math.sin(angleRad) * speed * 0.1

    ActiveRockets[rocket] = true
    playLaunchEffects(origin)

    CreateThread(function()
        while ActiveRockets[rocket] do
            Wait(0)
            local pos = GetEntityCoords(rocket)

            -- velocity update
            vx = math.cos(headingRad) * speed * 0.1
            vy = math.sin(headingRad) * speed * 0.1
            vz = vz - Config.Rocket.Gravity * 0.1

            -- position update
            local newPos = vec3(pos.x + vx, pos.y + vy, pos.z + vz)
            SetEntityCoordsNoOffset(rocket, newPos.x, newPos.y, newPos.z, false, false, false)

            -- update orientation
            local length = math.sqrt((vx * vx) + (vy * vy) + (vz * vz))
            if length > 0.01 then
                local pitch = math.deg(math.asin(-vz / length))
                local yaw = math.deg(math.atan(vy, vx))
                SetEntityRotation(rocket, pitch, 0.0, yaw, 2, true)
            end

            UseParticleFxAssetNextCall('core')
            StartParticleFxNonLoopedOnEntity('exp_grd_burst_fire', rocket, 0.0, -1.2, 0.0, 0.0, 0.0, 0.0, 0.7, false, false, false)

            local hit, hitPos = GetGroundZFor_3dCoord(newPos.x, newPos.y, newPos.z, false)
            if (hit and newPos.z <= (hitPos + 0.3)) or vz < -5.0 then
                ActiveRockets[rocket] = nil
                DeleteEntity(rocket)
                createMegaExplosion(newPos)
                break
            end

            speed = speed * 0.999
            if speed < 1.0 then
                ActiveRockets[rocket] = nil
                DeleteEntity(rocket)
                createMegaExplosion(newPos)
                break
            end
        end
    end)
end

RegisterNetEvent('rocket_system:client:syncPads', function(newPads)
    refreshPads(newPads)
end)

RegisterNetEvent('rocket_system:client:createPadAtPlayer', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local forward = GetEntityForwardVector(ped)
    local targetX = pos.x + forward.x * 2.0
    local targetY = pos.y + forward.y * 2.0
    local foundGround, groundZ = GetGroundZFor_3dCoord(targetX, targetY, pos.z + 100.0, false)

    local spawnPos = vec3(targetX, targetY, foundGround and groundZ or pos.z)
    TriggerServerEvent('rocket_system:server:createPad', spawnPos, heading)
end)

RegisterNetEvent('rocket_system:client:launchRocket', function(padId, pad)
    if Pads[padId] then
        Pads[padId] = pad
    end
    launchRocket(pad)
end)

RegisterNetEvent('rocket_system:client:showStatus', function()
    QBCore.Functions.TriggerCallback('rocket_system:server:getAllPads', function(allPads)
        local lines = {}
        for id, pad in pairs(allPads) do
            lines[#lines + 1] = ("Pad #%d | Fuel: %d | Ammo: %d | Angle: %d | Cooldown: %d")
                :format(id, pad.fuel, pad.ammo, pad.armAngle, math.max(0, pad.cooldownEnd - os.time()))
        end
        if #lines == 0 then lines[1] = 'No launch pads created yet.' end
        TriggerEvent('chat:addMessage', {
            color = { 255, 120, 50 },
            multiline = true,
            args = { _L('status_title'), table.concat(lines, '\n') }
        })
    end)
end)

RegisterNetEvent('rocket_system:client:openPadMenu', function(id)
    local pad = Pads[id]
    if not pad then
        QBCore.Functions.Notify(_L('no_pad_found'), 'error')
        return
    end

    openMenuCompat({
        {
            header = _L('menu_title'),
            isMenuHeader = true
        },
        {
            header = _L('menu_raise_arm'),
            txt = ('Current: %s'):format(pad.raised and 'UP' or 'DOWN'),
            params = {
                event = 'rocket_system:client:raiseArm',
                args = { id = id }
            }
        },
        {
            header = _L('menu_set_angle'),
            txt = ('Current angle: %d°'):format(pad.armAngle),
            params = {
                event = 'rocket_system:client:openAngleMenu',
                args = { id = id }
            }
        },
        {
            header = _L('menu_fire'),
            txt = ('Fuel: %d | Ammo: %d'):format(pad.fuel, pad.ammo),
            params = {
                event = 'rocket_system:client:tryFire',
                args = { id = id }
            }
        },
        {
            header = _L('menu_refill'),
            txt = 'Refill resources and reset cooldown',
            params = {
                isServer = true,
                event = 'rocket_system:server:refillPad',
                args = id
            }
        },
        {
            header = _L('menu_close')
        }
    })
end)

RegisterNetEvent('rocket_system:client:raiseArm', function(data)
    local id = data.id
    local pad = Pads[id]
    if not pad then return end

    pad.raised = not pad.raised
    pad.armAngle = pad.raised and math.max(pad.armAngle, 30) or 15

    TriggerServerEvent('rocket_system:server:updatePadState', id, {
        raised = pad.raised,
        armAngle = pad.armAngle
    })
end)

RegisterNetEvent('rocket_system:client:openAngleMenu', function(data)
    local id = data.id
    local entries = {
        {
            header = _L('menu_angle_title'),
            isMenuHeader = true
        }
    }

    local descriptions = {
        [15] = _L('angle_short'),
        [30] = _L('angle_medium'),
        [45] = _L('angle_optimal'),
        [60] = _L('angle_far'),
        [75] = _L('angle_very_far')
    }

    for _, angle in ipairs(Config.Angles) do
        entries[#entries + 1] = {
            header = ('%d°'):format(angle),
            txt = descriptions[angle],
            params = {
                event = 'rocket_system:client:setAngle',
                args = { id = id, angle = angle }
            }
        }
    end

    openMenuCompat(entries)
end)

RegisterNetEvent('rocket_system:client:setAngle', function(data)
    local id, angle = data.id, data.angle
    local pad = Pads[id]
    if not pad then return end

    pad.armAngle = angle
    pad.raised = true

    TriggerServerEvent('rocket_system:server:updatePadState', id, {
        armAngle = angle,
        raised = true
    })
end)

RegisterNetEvent('rocket_system:client:tryFire', function(data)
    local id = data.id
    QBCore.Functions.TriggerCallback('rocket_system:server:canFire', function(canFire, reason, extra)
        if not canFire then
            if reason == 'cooldown_active' then
                QBCore.Functions.Notify(_L(reason, extra or 0), 'error')
            else
                QBCore.Functions.Notify(_L(reason), 'error')
            end
            return
        end
    end, id)
end)

CreateThread(function()
    QBCore.Functions.TriggerCallback('rocket_system:server:getAllPads', function(allPads)
        refreshPads(allPads)
    end)
end)

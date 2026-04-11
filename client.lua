local QBCore = exports['qb-core']:GetCoreObject()

local launchPads = {}
local activeMissions = {}
local waypointTarget = nil
local padsSpawned = false

local function dbg(...)
    if Config.Debug then
        print('[missile]', ...)
    end
end

local function ensureModel(modelName)
    local model = joaat(modelName)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    return model
end

local function ensurePtfx(asset)
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end
end

local function getWaypointCoords()
    local blip = GetFirstBlipInfoId(8)
    if blip == 0 or not DoesBlipExist(blip) then
        return nil
    end

    local c = GetBlipInfoIdCoord(blip)
    local found, groundZ = GetGroundZFor_3dCoord(c.x, c.y, 1200.0, false)
    local z = found and groundZ or c.z
    return vec3(c.x, c.y, z)
end

local function playLaunchAudio(coords)
    PlaySoundFromCoord(-1, '5_SEC_WARNING', coords.x, coords.y, coords.z, 'HUD_MINI_GAME_SOUNDSET', false, 0, false)
end

local function setupTargetForPad(pad, idx)
    exports['qb-target']:AddTargetEntity(pad, {
        options = {
            {
                icon = 'fas fa-map-marked-alt',
                label = 'تحديد الهدف من الخريطة',
                action = function()
                    local target = getWaypointCoords()
                    if not target then
                        QBCore.Functions.Notify('حط Waypoint على الخريطة أولاً.', 'error')
                        return
                    end

                    waypointTarget = target
                    QBCore.Functions.Notify(('تم تحديد الهدف: %.1f / %.1f / %.1f'):format(target.x, target.y, target.z), 'success')
                end
            },
            {
                icon = 'fas fa-rocket',
                label = 'بدء عملية الإطلاق',
                action = function()
                    if not waypointTarget then
                        QBCore.Functions.Notify('حدد الهدف أولاً من الخريطة.', 'error')
                        return
                    end

                    TriggerServerEvent('missile:server:requestLaunch', idx, waypointTarget)
                end
            }
        },
        distance = 2.5
    })
end

local function spawnPads()
    if padsSpawned then
        return
    end

    padsSpawned = true
    local padModel = ensureModel(Config.Models.pad)

    for i, data in ipairs(Config.LaunchPads) do
        local c = data.coords
        local obj = CreateObjectNoOffset(padModel, c.x, c.y, c.z - 1.0, false, false, false)
        SetEntityHeading(obj, c.w)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        SetEntityAsMissionEntity(obj, true, true)

        launchPads[i] = obj
        setupTargetForPad(obj, i)
    end
end

local function simulateMissile(mission)
    local missileModel = ensureModel(Config.Models.missile)
    ensurePtfx(Config.Missile.particleAsset)

    local missile = CreateObjectNoOffset(missileModel, mission.start.x, mission.start.y, mission.start.z, false, false, false)
    SetEntityAsMissionEntity(missile, true, true)

    local pos = vec3(mission.start.x, mission.start.y, mission.start.z)
    local forward = vec3(0.0, 0.0, 1.0)
    local tick = 0.016

    UseParticleFxAssetNextCall(Config.Missile.particleAsset)
    local ptfxHandle = StartParticleFxLoopedOnEntity(
        Config.Missile.particleName,
        missile,
        0.0,
        0.0,
        -0.8,
        0.0,
        0.0,
        0.0,
        Config.Missile.particleScale,
        false,
        false,
        false
    )

    playLaunchAudio(pos)

    local elapsed = 0.0
    while elapsed < mission.totalTime do
        Wait(Config.Missile.updateMs)
        elapsed = elapsed + tick

        if elapsed < Config.Missile.ascentDuration then
            pos = pos + vec3(0.0, 0.0, Config.Missile.ascentSpeed * tick)
        else
            local toTarget = (mission.target - pos)
            local distance = #toTarget
            if distance < 2.0 then
                break
            end

            local desired = toTarget / distance
            forward = forward + (desired - forward) * math.min(Config.Missile.turnRate * tick, 1.0)
            local speed = Config.Missile.cruiseSpeed
            pos = pos + (forward * speed * tick)
        end

        local heading = GetHeadingFromVector_2d(forward.x, forward.y)
        local pitch = -math.deg(math.atan(forward.z, math.sqrt(forward.x * forward.x + forward.y * forward.y)))

        SetEntityCoordsNoOffset(missile, pos.x, pos.y, pos.z, false, false, false)
        SetEntityRotation(missile, pitch, 0.0, heading, 2, true)
    end

    if ptfxHandle and ptfxHandle ~= 0 then
        StopParticleFxLooped(ptfxHandle, false)
    end

    if DoesEntityExist(missile) then
        DeleteEntity(missile)
    end

    SetModelAsNoLongerNeeded(missileModel)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(750)
    spawnPads()
end)

RegisterNetEvent('missile:client:syncLaunch', function(mission)
    if not mission or not mission.id then
        return
    end

    mission.start = vec3(mission.start.x, mission.start.y, mission.start.z)
    mission.target = vec3(mission.target.x, mission.target.y, mission.target.z)

    activeMissions[mission.id] = mission

    CreateThread(function()
        simulateMissile(mission)
        activeMissions[mission.id] = nil
    end)
end)

RegisterNetEvent('missile:client:syncImpact', function(impact)
    local center = vec3(impact.x, impact.y, impact.z)

    for i = 1, Config.Explosion.count do
        local randomOffset = vec3(
            math.random(-Config.Explosion.radius * 100, Config.Explosion.radius * 100) / 100.0,
            math.random(-Config.Explosion.radius * 100, Config.Explosion.radius * 100) / 100.0,
            0.0
        )

        local boomPos = center + randomOffset

        AddExplosion(
            boomPos.x,
            boomPos.y,
            boomPos.z,
            Config.Explosion.type,
            Config.Explosion.damageScale,
            true,
            false,
            Config.Explosion.radius,
            true
        )

        PlaySoundFromCoord(-1, 'EXPLOSION', boomPos.x, boomPos.y, boomPos.z, 'MP_LOBBY_SOUNDS', false, 0, false)

        local ped = PlayerPedId()
        local pedPos = GetEntityCoords(ped)
        if #(pedPos - boomPos) <= Config.Explosion.cameraShakeRange then
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', Config.Explosion.cameraShakeIntensity)
        end

        Wait(Config.Explosion.intervalMs)
    end
end)

CreateThread(function()
    Wait(1200)
    spawnPads()
end)

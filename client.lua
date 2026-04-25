local QBCore = exports['qb-core']:GetCoreObject()

local launcher = {
    platform = nil,
    arm = nil,
    missile = nil,
    button = nil,
    rope = nil,
    selectedTarget = nil,
    launching = false,
    initialized = false,
    zones = {}
}

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then
        return nil
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(25)
    end

    return hash
end

local function loadPtfx(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(25)
    end
end

local function showNotify(message, nType)
    QBCore.Functions.Notify(message, nType or 'primary')
end

local function cleanupMissile()
    if launcher.missile and DoesEntityExist(launcher.missile) then
        DeleteEntity(launcher.missile)
    end
    launcher.missile = nil
end

local function createMissileAttached()
    cleanupMissile()
    local hash = loadModel(Config.Models.missile)
    if not hash then
        showNotify('Missile model not found in game files.', 'error')
        return
    end

    local armCoords = GetEntityCoords(launcher.arm)
    launcher.missile = CreateObject(hash, armCoords.x, armCoords.y, armCoords.z + 0.5, true, true, false)
    SetEntityAsMissionEntity(launcher.missile, true, true)
    AttachEntityToEntity(
        launcher.missile,
        launcher.arm,
        0,
        Config.MissileOffset.x,
        Config.MissileOffset.y,
        Config.MissileOffset.z,
        0.0,
        0.0,
        0.0,
        false,
        false,
        false,
        false,
        2,
        true
    )

    SetModelAsNoLongerNeeded(hash)
end

local function createCable()
    if not Config.Rope.enabled then return end

    RopeLoadTextures()
    while not RopeAreTexturesLoaded() do
        Wait(25)
    end

    local startCoords = GetEntityCoords(launcher.platform)
    local endCoords = GetEntityCoords(launcher.button)

    launcher.rope = AddRope(
        startCoords.x,
        startCoords.y,
        startCoords.z + 1.2,
        0.0,
        0.0,
        0.0,
        Config.Rope.length,
        4,
        Config.Rope.length,
        Config.Rope.minLength,
        0.5,
        false,
        false,
        true,
        Config.Rope.timeMultiplier,
        false,
        0
    )

    if launcher.rope and launcher.rope ~= 0 then
        AttachEntitiesToRope(
            launcher.rope,
            launcher.platform,
            launcher.button,
            startCoords.x,
            startCoords.y,
            startCoords.z + 1.2,
            endCoords.x,
            endCoords.y,
            endCoords.z + 0.25,
            Config.Rope.length,
            false,
            false,
            nil,
            nil
        )
    end
end

local function buildMenu()
    local menu = {
        {
            header = '🚀 Missile Guidance Targets',
            isMenuHeader = true
        }
    }

    for i, target in ipairs(Config.Targets) do
        menu[#menu + 1] = {
            header = target.name,
            txt = ('Coords: %.2f, %.2f, %.2f'):format(target.coords.x, target.coords.y, target.coords.z),
            params = {
                event = 'missile:client:setTarget',
                args = i
            }
        }
    end

    menu[#menu + 1] = {
        header = '⬅ Close',
        params = { event = 'qb-menu:closeMenu' }
    }

    TriggerEvent('qb-menu:client:openMenu', menu)
end

RegisterNetEvent('missile:client:setTarget', function(index)
    local target = Config.Targets[index]
    if not target then return end

    launcher.selectedTarget = index
    showNotify(('Target selected: %s'):format(target.name), 'success')
end)

local function raiseArmAnimation()
    local startPitch = Config.Launch.armStartPitch
    local endPitch = Config.Launch.armReadyPitch
    local totalDuration = Config.Launch.armRaiseDuration
    local steps = 50

    for i = 0, steps do
        local t = i / steps
        local pitch = startPitch + (endPitch - startPitch) * t
        SetEntityRotation(launcher.arm, pitch, 0.0, Config.LaunchSite.heading, 2, true)
        Wait(math.floor(totalDuration / steps))
    end
end

local function playButtonPressAnimation()
    local ped = PlayerPedId()
    local dict = 'anim@mp_player_intmenu@key_fob@'
    local anim = 'fob_click'

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskTurnPedToFaceEntity(ped, launcher.button, 750)
    Wait(600)
    TaskPlayAnim(ped, dict, anim, 2.0, 2.0, 1200, 49, 0.0, false, false, false)
    PlaySoundFrontend(-1, Config.Effects.clickSound, Config.Effects.soundSet, false)
end

local function launchMissile(target)
    if not launcher.missile or not DoesEntityExist(launcher.missile) then
        createMissileAttached()
    end

    if not launcher.missile then return end

    DetachEntity(launcher.missile, true, true)
    SetEntityCollision(launcher.missile, true, true)
    SetEntityDynamic(launcher.missile, true)
    SetEntityInvincible(launcher.missile, true)

    local camShake = Config.Effects.launchCameraShake
    ShakeGameplayCam(camShake.name, camShake.intensity)
    SetTimeout(camShake.durationMs, function()
        StopGameplayCamShaking(true)
    end)

    PlaySoundFromCoord(-1, Config.Effects.launchSound, GetEntityCoords(launcher.missile), Config.Effects.soundSet, false, 0, false)

    loadPtfx('core')
    UseParticleFxAssetNextCall('core')
    local smokeFx = StartParticleFxLoopedOnEntity('exp_grd_bzgas_smoke', launcher.missile, 0.0, 0.0, -0.3, 0.0, 0.0, 0.0, 1.35, false, false, false)
    UseParticleFxAssetNextCall('core')
    local flameFx = StartParticleFxLoopedOnEntity('ent_sht_steam', launcher.missile, 0.0, -0.2, -0.5, 0.0, 0.0, 0.0, 1.65, false, false, false)

    local forward = GetEntityForwardVector(launcher.arm)
    local initialVelocity = vector3(forward.x * 8.0, forward.y * 8.0, Config.Launch.missileInitialSpeed)
    SetEntityVelocity(launcher.missile, initialVelocity.x, initialVelocity.y, initialVelocity.z)

    local startTime = GetGameTimer()
    local curveDelay = Config.Launch.curveStartDelayMs

    while launcher.missile and DoesEntityExist(launcher.missile) do
        local now = GetGameTimer()
        local elapsed = now - startTime
        local missileCoords = GetEntityCoords(launcher.missile)
        local distance = #(missileCoords - target.coords)

        if distance <= Config.Launch.proximityDetonation or elapsed >= Config.Launch.maxTravelTimeMs then
            StopParticleFxLooped(smokeFx, false)
            StopParticleFxLooped(flameFx, false)

            UseParticleFxAssetNextCall('core')
            StartParticleFxNonLoopedAtCoord('exp_grd_flare', target.coords.x, target.coords.y, target.coords.z, 0.0, 0.0, 0.0, 2.2, false, false, false)
            AddExplosion(target.coords.x, target.coords.y, target.coords.z, 29, 8.0, true, false, Config.Launch.damageRadius)

            DeleteEntity(launcher.missile)
            launcher.missile = nil
            break
        end

        if elapsed > curveDelay then
            local desiredDir = target.coords - missileCoords
            local length = #(desiredDir)
            if length > 0.001 then
                desiredDir = desiredDir / length
                local currentVelocity = GetEntityVelocity(launcher.missile)
                local blend = 0.08
                local desiredVelocity = desiredDir * Config.Launch.homingSpeed

                local newVelocity = vector3(
                    currentVelocity.x + (desiredVelocity.x - currentVelocity.x) * blend,
                    currentVelocity.y + (desiredVelocity.y - currentVelocity.y) * blend,
                    currentVelocity.z + (desiredVelocity.z - currentVelocity.z) * blend
                )

                SetEntityVelocity(launcher.missile, newVelocity.x, newVelocity.y, newVelocity.z)
                SetEntityHeading(launcher.missile, GetHeadingFromVector_2d(desiredDir.x, desiredDir.y))
            end
        end

        Wait(0)
    end

    launcher.launching = false
    -- Reset arm to idle and respawn missile on arm for next use.
    SetEntityRotation(launcher.arm, Config.Launch.armStartPitch, 0.0, Config.LaunchSite.heading, 2, true)
    createMissileAttached()
end

RegisterNetEvent('missile:client:authorizedLaunch', function(targetIndex)
    local target = Config.Targets[targetIndex]
    if not target then
        launcher.launching = false
        showNotify('Invalid launch target.', 'error')
        return
    end

    CreateThread(function()
        launchMissile(target)
    end)
end)

RegisterNetEvent('missile:client:denyLaunch', function(reason)
    launcher.launching = false
    showNotify(reason or 'Launch denied by server.', 'error')
end)

local function validateBeforeLaunch()
    if launcher.launching then
        showNotify('Launch sequence is already active.', 'error')
        return false
    end

    if not launcher.selectedTarget then
        showNotify('Select a target first from guidance panel.', 'error')
        return false
    end

    local ped = PlayerPedId()
    local dist = #(GetEntityCoords(ped) - Config.LaunchSite.coords)
    if dist > Config.LaunchSite.maxPlayerDistance then
        showNotify('Too far from launch platform.', 'error')
        return false
    end

    return true
end

local function beginLaunchSequence()
    if not validateBeforeLaunch() then return end

    launcher.launching = true
    local targetData = Config.Targets[launcher.selectedTarget]

    showNotify(('Locked target: %s'):format(targetData.name), 'primary')

    playButtonPressAnimation()
    raiseArmAnimation()

    for i = Config.Launch.countdownSeconds, 1, -1 do
        showNotify(('Launch in %d...'):format(i), 'error')
        Wait(1000)
    end

    TriggerServerEvent('missile:server:requestLaunch', launcher.selectedTarget)
end

RegisterNetEvent('missile:client:openTargets', function()
    buildMenu()
end)

local function addTargetInteractions()
    if not launcher.platform or not DoesEntityExist(launcher.platform) then
        print('[missile] platform entity does not exist, cannot register target zones')
        return
    end

    local buttonCoords = GetEntityCoords(launcher.button)
    local platformCoords = GetEntityCoords(launcher.platform)

    launcher.zones.button = 'missile_launch_button_zone'
    launcher.zones.platform = 'missile_platform_zone'

    exports['qb-target']:AddBoxZone(launcher.zones.button, buttonCoords, 0.8, 0.8, {
        name = launcher.zones.button,
        heading = GetEntityHeading(launcher.button),
        minZ = buttonCoords.z - 0.4,
        maxZ = buttonCoords.z + 0.8,
        debugPoly = false
    }, {
        options = {
            {
                icon = 'fas fa-bullseye',
                label = 'Open Target List',
                action = function()
                    buildMenu()
                end
            },
            {
                icon = 'fas fa-rocket',
                label = 'Press Emergency Launch Button',
                action = function()
                    beginLaunchSequence()
                end
            }
        },
        distance = Config.LaunchSite.interactionDistance
    })

    exports['qb-target']:AddBoxZone(launcher.zones.platform, platformCoords, 2.2, 2.2, {
        name = launcher.zones.platform,
        heading = GetEntityHeading(launcher.platform),
        minZ = platformCoords.z - 1.0,
        maxZ = platformCoords.z + 2.5,
        debugPoly = false
    }, {
        options = {
            {
                icon = 'fas fa-satellite-dish',
                label = 'Select Guidance Target',
                action = function()
                    buildMenu()
                end
            }
        },
        distance = Config.LaunchSite.interactionDistance + 1.0
    })
end

local function spawnLauncher()
    if launcher.initialized then return end

    local platformHash = loadModel(Config.Models.platform)
    local armHash = loadModel(Config.Models.arm)
    local buttonHash = loadModel(Config.Models.button)

    if not platformHash or not armHash or not buttonHash then
        print('[missile] missing models, launcher could not be created')
        return
    end

    launcher.platform = CreateObject(platformHash, Config.LaunchSite.coords.x, Config.LaunchSite.coords.y, Config.LaunchSite.coords.z - 1.0, false, true, false)
    SetEntityHeading(launcher.platform, Config.LaunchSite.heading)
    FreezeEntityPosition(launcher.platform, true)

    local armWorld = GetOffsetFromEntityInWorldCoords(launcher.platform, Config.ArmOffset.x, Config.ArmOffset.y, Config.ArmOffset.z)
    launcher.arm = CreateObject(armHash, armWorld.x, armWorld.y, armWorld.z, false, true, false)
    SetEntityHeading(launcher.arm, Config.LaunchSite.heading)
    FreezeEntityPosition(launcher.arm, true)
    AttachEntityToEntity(launcher.arm, launcher.platform, 0, Config.ArmOffset.x, Config.ArmOffset.y, Config.ArmOffset.z, Config.Launch.armStartPitch, 0.0, 0.0, false, false, false, false, 2, true)

    local buttonWorld = GetOffsetFromEntityInWorldCoords(launcher.platform, Config.ButtonOffset.x, Config.ButtonOffset.y, Config.ButtonOffset.z)
    launcher.button = CreateObject(buttonHash, buttonWorld.x, buttonWorld.y, buttonWorld.z, false, true, false)
    SetEntityHeading(launcher.button, Config.LaunchSite.heading + 35.0)
    FreezeEntityPosition(launcher.button, true)

    if not DoesEntityExist(launcher.platform) or not DoesEntityExist(launcher.arm) or not DoesEntityExist(launcher.button) then
        print('[missile] one or more launcher props failed to spawn')
        return
    end

    createCable()
    createMissileAttached()
    addTargetInteractions()

    SetModelAsNoLongerNeeded(platformHash)
    SetModelAsNoLongerNeeded(armHash)
    SetModelAsNoLongerNeeded(buttonHash)

    launcher.initialized = true
end

CreateThread(function()
    Wait(1500)
    spawnLauncher()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if launcher.rope and launcher.rope ~= 0 then
        DeleteRope(launcher.rope)
        launcher.rope = nil
    end

    cleanupMissile()

    if launcher.zones.button then
        exports['qb-target']:RemoveZone(launcher.zones.button)
        launcher.zones.button = nil
    end

    if launcher.zones.platform then
        exports['qb-target']:RemoveZone(launcher.zones.platform)
        launcher.zones.platform = nil
    end

    if launcher.arm and DoesEntityExist(launcher.arm) then DeleteEntity(launcher.arm) end
    if launcher.button and DoesEntityExist(launcher.button) then DeleteEntity(launcher.button) end
    if launcher.platform and DoesEntityExist(launcher.platform) then DeleteEntity(launcher.platform) end
end)

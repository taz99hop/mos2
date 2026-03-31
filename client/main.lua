local QBCore = exports['qb-core']:GetCoreObject()

local ClientState = {
    commanderSrc = nil,
    missileEntities = {},
    radarTracks = {},
    uiOpen = false,
    blackout = 0,
    platforms = {}
}

local function loadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
    end
end

local function setNui(show)
    ClientState.uiOpen = show
    SetNuiFocus(show, show)
    SendNUIMessage({ action = 'toggle', show = show })
end

local function getTargetFromWaypoint()
    local blip = GetFirstBlipInfoId(8)
    if DoesBlipExist(blip) then
        local x, y, z = table.unpack(GetBlipInfoIdCoord(blip))
        return vector3(x, y, z)
    end
    return nil
end

local function spawnMissileObject(packet)
    loadModel(Config.Visual.missileModel)
    local ent = CreateObjectNoOffset(Config.Visual.missileModel, packet.source.x, packet.source.y, packet.source.z, true, true, false)
    SetEntityDynamic(ent, true)
    SetEntityCollision(ent, false, false)
    SetEntityInvincible(ent, true)

    packet.localSpawnTime = GetGameTimer()
    ClientState.missileEntities[packet.id] = {
        entity = ent,
        packet = packet,
        spawnedAt = packet.localSpawnTime
    }

    UseParticleFxAssetNextCall(Config.Visual.launchFx)
    StartParticleFxNonLoopedAtCoord(
        Config.Visual.launchFxName,
        packet.source.x,
        packet.source.y,
        packet.source.z,
        0.0,
        0.0,
        0.0,
        1.2,
        false,
        false,
        false
    )
end

local function removeMissileObject(id)
    local data = ClientState.missileEntities[id]
    if data and DoesEntityExist(data.entity) then
        DeleteEntity(data.entity)
    end
    ClientState.missileEntities[id] = nil
end

RegisterNetEvent('mos2:client:commanderChanged', function(src)
    ClientState.commanderSrc = src
    SendNUIMessage({ action = 'commander', serverId = src or 0 })
end)

RegisterNetEvent('mos2:client:spawnMissile', function(packet)
    spawnMissileObject(packet)
end)

RegisterNetEvent('mos2:client:despawnMissile', function(id)
    removeMissileObject(id)
end)

RegisterNetEvent('mos2:client:missileExplode', function(_, pos, blastRadius, damageScale)
    AddExplosion(pos.x, pos.y, pos.z, 29, 1.2 * damageScale, true, false, blastRadius)
    UseParticleFxAssetNextCall(Config.Visual.launchFx)
    StartParticleFxNonLoopedAtCoord(Config.Visual.smokeFxName, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 1.4, false, false, false)
end)

RegisterNetEvent('mos2:client:clusterSplitFx', function(_, pos)
    PlaySoundFrontend(-1, Config.Visual.splitSound, 'HUD_MINI_GAME_SOUNDSET', true)
    UseParticleFxAssetNextCall(Config.Visual.launchFx)
    StartParticleFxNonLoopedAtCoord(Config.Visual.splitFxName, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.8, false, false, false)
end)

RegisterNetEvent('mos2:client:launchInterceptorFx', function(fromPos, toPos)
    DrawLine(fromPos.x, fromPos.y, fromPos.z, toPos.x, toPos.y, toPos.z, 0, 120, 255, 220)
end)

RegisterNetEvent('mos2:client:missileIntercepted', function(id, pos)
    removeMissileObject(id)
    AddExplosion(pos.x, pos.y, pos.z, 4, 0.35, false, true, 2.0)
end)

RegisterNetEvent('mos2:client:radarTracks', function(tracks)
    ClientState.radarTracks = tracks
    SendNUIMessage({ action = 'tracks', tracks = tracks })
end)

RegisterNetEvent('mos2:client:radarOffline', function(seconds)
    SendNUIMessage({ action = 'radar_offline', seconds = seconds })
end)

RegisterNetEvent('mos2:client:blackout', function(level)
    ClientState.blackout = level
    SetArtificialLightsState(level >= 50)
    SendNUIMessage({ action = 'blackout', level = level })
end)

RegisterNetEvent('mos2:client:launchAnnouncement', function(data)
    PlaySoundFrontend(-1, Config.Visual.sirenSound, 'HUD_AWARDS', true)
    QBCore.Functions.Notify(("Incoming Missile | ETA: %ss | Type: %s"):format(data.eta, data.missileType), 'error', 5000)
    SendNUIMessage({ action = 'launch', data = data })
end)

CreateThread(function()
    while true do
        local now = GetGameTimer()
        for id, data in pairs(ClientState.missileEntities) do
            local packet = data.packet
            local t = (now - (packet.localSpawnTime or now)) / 1000.0
            local pos = Ballistics.positionAt(packet.source, packet.velocity0, packet.spec.gravity, t)
            if DoesEntityExist(data.entity) then
                local vel = Ballistics.velocityAt(packet.velocity0, packet.spec.gravity, t)
                local dir = Ballistics.normalize(vel)
                SetEntityCoordsNoOffset(data.entity, pos.x, pos.y, pos.z, false, false, false)
                SetEntityRotation(data.entity, -math.deg(math.atan2(dir.z, math.sqrt(dir.x * dir.x + dir.y * dir.y))), 0.0, Ballistics.bearingFromVelocity(dir), 2, true)
            end
            if t >= packet.totalFlightTime + 2.0 then
                removeMissileObject(id)
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if ClientState.uiOpen then
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            for _, zone in ipairs(Config.AirZones) do
                DrawMarker(1, zone.center.x, zone.center.y, zone.center.z - 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    zone.radius * 2.0, zone.radius * 2.0, 40.0,
                    zone.type == 'safe' and 20 or 220,
                    zone.type == 'safe' and 140 or 30,
                    zone.type == 'safe' and 255 or 30,
                    25, false, false, 2, false, nil, nil, false)

                if #(pcoords - zone.center) <= zone.radius then
                    DrawTxt3D(zone.center + vector3(0.0, 0.0, 60.0), ('%s [%s]'):format(zone.name, zone.type))
                end
            end
        end
        Wait(0)
    end
end)

function DrawTxt3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

RegisterCommand(Config.OpenUiCommand, function()
    setNui(not ClientState.uiOpen)
    if ClientState.uiOpen then
        TriggerServerEvent('mos2:server:requestCommander')
    end
end)

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb('ok')
end)

RegisterNUICallback('requestBootstrap', function(_, cb)
    QBCore.Functions.TriggerCallback('mos2:server:getBootstrap', function(data)
        ClientState.platforms = data.platforms or {}
        SendNUIMessage({ action = 'platforms', platforms = ClientState.platforms })
        cb(data)
    end)
end)

RegisterNUICallback('fireMission', function(data, cb)
    local target = getTargetFromWaypoint()
    if not target and data.laserTarget then
        target = vector3(data.laserTarget.x, data.laserTarget.y, data.laserTarget.z)
    end

    if not target then
        QBCore.Functions.Notify('ضع Waypoint أو استخدم Laser Designator أولاً.', 'error')
        cb({ ok = false })
        return
    end

    TriggerServerEvent('mos2:server:launchMission', {
        target = { x = target.x, y = target.y, z = target.z },
        typeKey = data.typeKey,
        count = data.count,
        launcherId = data.launcherId
    })

    cb({ ok = true })
end)

local QBCore = exports['qb-core']:GetCoreObject()

local State = {
    missiles = {},
    commanderSrc = nil,
    commanderCid = nil,
    radarDisabledUntil = 0,
    blackoutLevel = 0,
    aaFireLog = {}
}

local function notify(src, msg, msgType)
    TriggerClientEvent('QBCore:Notify', src, msg, msgType or 'primary')
end

local function tableCount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function nowMs()
    return GetGameTimer()
end

local function isCommander(src)
    if not src then return false end

    if Config.TestingAllowAllPlayers then
        return true
    end

    local ply = QBCore.Functions.GetPlayer(src)
    if not ply then return false end
    local cid = ply.PlayerData.citizenid
    if State.commanderCid and State.commanderCid == cid then
        return true
    end
    return cid == Config.CommanderCitizenId
end

local function setCommander(src)
    local ply = QBCore.Functions.GetPlayer(src)
    if not ply then return false end
    State.commanderSrc = src
    State.commanderCid = ply.PlayerData.citizenid
    TriggerClientEvent('mos2:client:commanderChanged', -1, State.commanderSrc)
    return true
end

local function clearCommanderIfDisconnected(src)
    if State.commanderSrc == src then
        State.commanderSrc = nil
        State.commanderCid = nil
        TriggerClientEvent('mos2:client:commanderChanged', -1, nil)
    end
end

local missileSeq = 0
local function nextMissileId()
    missileSeq = missileSeq + 1
    return ('M-%06d'):format(missileSeq)
end

local function registerMissile(packet)
    if tableCount(State.missiles) >= Config.MaxActiveMissiles then
        return false, 'Maximum active missiles reached.'
    end

    State.missiles[packet.id] = packet
    TriggerClientEvent('mos2:client:spawnMissile', -1, packet)
    return true
end

local function missileZoneName(pos)
    for _, zone in ipairs(Config.AirZones) do
        if #(pos - zone.center) <= zone.radius then
            return zone.name, zone.type
        end
    end
    return 'OUTSIDE', 'unknown'
end

local function impactEffects(missile)
    local pos = missile.currentPos

    for _, power in ipairs(Config.TargetImpacts.power_stations) do
        if #(pos - power.coords) <= power.radius then
            State.blackoutLevel = math.min(100, State.blackoutLevel + 35)
            TriggerClientEvent('mos2:client:blackout', -1, State.blackoutLevel)
        end
    end

    for _, radar in ipairs(Config.TargetImpacts.radars) do
        if #(pos - radar.coords) <= radar.radius then
            State.radarDisabledUntil = nowMs() + 120000
        end
    end
end

local function removeMissile(id, reason)
    local missile = State.missiles[id]
    if not missile then return end

    TriggerClientEvent('mos2:client:missileExplode', -1, id, missile.currentPos, missile.spec.blastRadius, missile.spec.damageScale)
    impactEffects(missile)

    State.missiles[id] = nil
    TriggerClientEvent('mos2:client:despawnMissile', -1, id, reason or 'impact')
end

local function splitClusterMissile(parent)
    local subCount = math.min(parent.spec.submunitionCount or 6, Config.MaxClusterSubmunitions)
    local subTargets = Ballistics.randomSubTargets(parent.targetPos, subCount, parent.spec.subSpreadRadius or 40.0)

    TriggerClientEvent('mos2:client:clusterSplitFx', -1, parent.id, parent.currentPos)

    for i = 1, #subTargets do
        local subSpec = {
            label = 'Cluster Sub',
            speed = parent.spec.speed * 0.9,
            arcFactor = 0.05,
            gravity = parent.spec.gravity,
            blastRadius = parent.spec.blastRadius,
            damageScale = parent.spec.damageScale,
            deviationBase = 0,
            cluster = false
        }

        local ballistic = Ballistics.solveLaunch(parent.currentPos, subTargets[i], subSpec)
        local subPacket = {
            id = nextMissileId(),
            typeKey = 'CLUSTER_SUB',
            spec = subSpec,
            launcher = parent.launcher,
            source = parent.currentPos,
            targetPos = subTargets[i],
            currentPos = parent.currentPos,
            velocity0 = ballistic.launchVelocity,
            launchTime = nowMs(),
            etaMs = math.floor(ballistic.timeOfFlight * 1000),
            totalFlightTime = ballistic.timeOfFlight,
            splitDone = true,
            createdAt = nowMs(),
            isSubmunition = true,
            zoneName = parent.zoneName
        }
        registerMissile(subPacket)
    end

    State.missiles[parent.id] = nil
    TriggerClientEvent('mos2:client:despawnMissile', -1, parent.id, 'cluster_split')
end

local function attemptAirDefense(missile)
    local now = nowMs()
    for _, aa in ipairs(Config.AntiAirBatteries) do
        if #(missile.currentPos - aa.coords) <= Config.InterceptorScanRadius then
            local slot = math.floor(now / 60000)
            local key = aa.id .. ':' .. slot
            State.aaFireLog[key] = State.aaFireLog[key] or 0
            if State.aaFireLog[key] < aa.maxShotsPerMinute then
                State.aaFireLog[key] = State.aaFireLog[key] + 1
                TriggerClientEvent('mos2:client:launchInterceptorFx', -1, aa.coords, missile.currentPos)

                if math.random() <= aa.interceptChance then
                    TriggerClientEvent('mos2:client:missileIntercepted', -1, missile.id, missile.currentPos)
                    State.missiles[missile.id] = nil
                    return true
                end
            end
        end
    end
    return false
end


local function getLaunchPlatform(platformId)
    for _, p in ipairs(Config.LaunchPlatforms or {}) do
        if p.id == platformId then
            return p
        end
    end
    return (Config.LaunchPlatforms or {})[1]
end

local function createMissile(sourcePos, targetPos, typeKey, launcherName)
    local spec = Config.MissileTypes[typeKey]
    if not spec then return nil, 'Unknown missile type.' end

    local distance = #(targetPos - sourcePos)
    local deviatedTarget = Ballistics.applyDeviation(targetPos, distance, spec.deviationBase)
    local ballistic = Ballistics.solveLaunch(sourcePos, deviatedTarget, spec)

    local id = nextMissileId()
    local zoneName = missileZoneName(sourcePos)

    local missile = {
        id = id,
        typeKey = typeKey,
        spec = spec,
        launcher = launcherName,
        source = sourcePos,
        targetPos = deviatedTarget,
        currentPos = sourcePos,
        velocity0 = ballistic.launchVelocity,
        launchTime = nowMs(),
        etaMs = math.floor(ballistic.timeOfFlight * 1000),
        totalFlightTime = ballistic.timeOfFlight,
        splitDone = false,
        createdAt = nowMs(),
        zoneName = zoneName,
        telemetry = {
            launchSpeed = ballistic.launchSpeed,
            pitchDeg = ballistic.pitchDeg,
            apex = ballistic.apex,
            distance = ballistic.distance
        }
    }

    local ok, err = registerMissile(missile)
    if not ok then return nil, err end
    return missile
end

local function runTelemetryPush()
    local now = nowMs()
    if State.radarDisabledUntil > now then
        TriggerClientEvent('mos2:client:radarOffline', -1, math.floor((State.radarDisabledUntil - now) / 1000))
        return
    end

    local tracks = {}
    for _, missile in pairs(State.missiles) do
        local t = (now - missile.launchTime) / 1000.0
        local vel = Ballistics.velocityAt(missile.velocity0, missile.spec.gravity, t)
        tracks[#tracks + 1] = {
            id = missile.id,
            typeKey = missile.typeKey,
            pos = missile.currentPos,
            speed = #(vel),
            heading = Ballistics.bearingFromVelocity(vel),
            eta = math.max(0, math.floor((missile.launchTime + missile.etaMs - now) / 1000)),
            zone = missile.zoneName
        }
    end
    TriggerClientEvent('mos2:client:radarTracks', -1, tracks)
end

RegisterNetEvent('mos2:server:requestCommander', function()
    local src = source
    if isCommander(src) then
        setCommander(src)
        notify(src, 'تم تعيينك كقائد أعلى.', 'success')
    else
        notify(src, 'لا تملك صلاحية القائد.', 'error')
    end
end)

RegisterNetEvent('mos2:server:launchMission', function(payload)
    local src = source
    if not isCommander(src) then
        notify(src, 'فقط القائد يستطيع الإطلاق.', 'error')
        return
    end

    if State.commanderSrc ~= src then
        setCommander(src)
    end

    local fireCount = Ballistics.clamp(tonumber(payload.count) or 1, 1, 8)
    local missileType = payload.typeKey or 'HE'
    local platform = getLaunchPlatform(payload.launcherId)
    if not platform then
        notify(src, 'لا توجد منصة إطلاق معرفة في الإعدادات.', 'error')
        return
    end

    local launcherPos = platform.muzzle
    local targetPos = vector3(payload.target.x, payload.target.y, payload.target.z)

    CreateThread(function()
        for i = 1, fireCount do
            local missile, err = createMissile(launcherPos, targetPos, missileType, platform.name)
            if missile then
                TriggerClientEvent('mos2:client:launchAnnouncement', -1, {
                    id = missile.id,
                    missileType = missile.typeKey,
                    eta = math.floor(missile.etaMs / 1000),
                    source = launcherPos,
                    target = missile.targetPos,
                    telemetry = missile.telemetry
                })
            elseif err then
                notify(src, ('فشل الإطلاق: %s'):format(err), 'error')
                break
            end
            Wait(math.random(Config.SequentialDelayMin, Config.SequentialDelayMax))
        end
    end)
end)

CreateThread(function()
    while true do
        local now = nowMs()
        for id, missile in pairs(State.missiles) do
            local t = (now - missile.launchTime) / 1000.0
            local pos = Ballistics.positionAt(missile.source, missile.velocity0, missile.spec.gravity, t)
            missile.currentPos = pos

            if missile.spec.cluster and not missile.splitDone then
                local progress = t / missile.totalFlightTime
                if progress >= (missile.spec.splitAtProgress or 0.7) or pos.z >= (missile.spec.splitAltitude or 120.0) then
                    missile.splitDone = true
                    splitClusterMissile(missile)
                    goto continue
                end
            end

            if attemptAirDefense(missile) then
                goto continue
            end

            if t >= missile.totalFlightTime or pos.z <= missile.targetPos.z + 1.0 then
                removeMissile(id, 'impact')
            end

            ::continue::
        end

        runTelemetryPush()
        Wait(Config.ServerTickMs)
    end
end)

AddEventHandler('playerDropped', function()
    clearCommanderIfDisconnected(source)
end)

QBCore.Functions.CreateCallback('mos2:server:getBootstrap', function(src, cb)
    cb({
        commander = State.commanderSrc,
        blackout = State.blackoutLevel,
        missileTypes = Config.MissileTypes,
        airZones = Config.AirZones,
        platforms = Config.LaunchPlatforms
    })
end)

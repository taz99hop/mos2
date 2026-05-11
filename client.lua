local systemEnabled = Config.RadarEnabledByDefault
local batteries = {}
local activeMissiles = {}

local threatClasses = {
    [15] = true, -- helicopter
    [16] = true, -- plane
}

local function dbg(...)
    if Config.Debug then
        print("[patriotaa]", ...)
    end
end

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(model)
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function loadPtfx(dict)
    RequestNamedPtfxAsset(dict)
    local timeout = GetGameTimer() + 5000
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function spawnCrew(vehicle)
    if not loadModel(Config.NpcModel) then return nil end
    local ped = CreatePedInsideVehicle(vehicle, 26, Config.NpcModel, Config.NpcSeat, true, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedKeepTask(ped, true)

    if loadAnimDict(Config.NpcAnim.dict) then
        TaskPlayAnim(ped, Config.NpcAnim.dict, Config.NpcAnim.name, 8.0, -8.0, -1, 49, 0.0, false, false, false)
    end

    return ped
end

local function spawnBattery(sp)
    if not loadModel(Config.VehicleModel) then
        dbg("model not found patriotaa")
        return
    end

    local c = sp.coords
    local veh = CreateVehicle(Config.VehicleModel, c.x, c.y, c.z, c.w, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleEngineOn(veh, true, true, false)
    FreezeEntityPosition(veh, true)

    local ped = spawnCrew(veh)
    table.insert(batteries, {
        vehicle = veh,
        operator = ped,
        protectedCenter = sp.protectedCenter,
        cooldownUntil = 0,
        missilesLeft = Config.MaxMissilesPerVehicle,
        tracked = {}
    })
end

local function headingTo(fromPos, toPos)
    local dx, dy = toPos.x - fromPos.x, toPos.y - fromPos.y
    return GetHeadingFromVector_2d(dx, dy)
end

local function isThreat(entity, battery)
    if not DoesEntityExist(entity) or entity == battery.vehicle then return false end

    local etype = GetEntityType(entity)
    if etype == 1 and Config.IgnorePedThreat then return false end

    if etype == 2 then
        local class = GetVehicleClass(entity)
        if Config.IgnoreCars and class < 15 then return false end
        if not threatClasses[class] then return false end
    elseif etype ~= 3 then
        return false
    end

    local vel = GetEntityVelocity(entity)
    local speed = #(vel)
    if speed < Config.MinThreatSpeed then return false end

    local ePos = GetEntityCoords(entity)
    local center = battery.protectedCenter
    local toCenter = center - ePos
    local distance = #(toCenter)
    if distance > Config.RadarRange then return false end

    local dir = toCenter / (distance > 0.01 and distance or 1.0)
    local velDir = vel / speed
    local approach = dir.x * velDir.x + dir.y * velDir.y + dir.z * velDir.z

    return approach > 0.55, speed, distance, approach
end

local function calcHitChance(speed, distance, approach)
    local speedScore = math.min(speed / 120.0, 1.0)
    local distScore = 1.0 - math.min(distance / Config.RadarRange, 1.0)
    local approachScore = math.max((approach - 0.5) * 2.0, 0.0)
    return (speedScore * 0.35) + (distScore * 0.30) + (approachScore * 0.35)
end

local function createInterceptor(battery, target)
    local veh = battery.vehicle
    local launchWorld = GetOffsetFromEntityInWorldCoords(veh, Config.LaunchOffset.x, Config.LaunchOffset.y, Config.LaunchOffset.z)
    local missile = CreateObject(`w_lr_rpg_rocket`, launchWorld.x, launchWorld.y, launchWorld.z, true, true, false)
    SetEntityAsMissionEntity(missile, true, true)
    SetEntityCollision(missile, false, false)

    if loadPtfx(Config.Effects.launchPtfx.dict) then
        UseParticleFxAssetNextCall(Config.Effects.launchPtfx.dict)
        StartParticleFxNonLoopedAtCoord(Config.Effects.launchPtfx.name, launchWorld.x, launchWorld.y, launchWorld.z, 0.0, 0.0, 0.0, Config.Effects.launchPtfx.scale, false, false, false)
    end

    PlaySoundFromCoord(-1, Config.Effects.launchSound, launchWorld.x, launchWorld.y, launchWorld.z, Config.Effects.launchSoundSet, false, 0, false)

    table.insert(activeMissiles, {
        entity = missile,
        target = target,
        createdAt = GetGameTimer(),
        battery = battery
    })
end

local function stepMissile(m)
    if not DoesEntityExist(m.entity) then return false end
    if not DoesEntityExist(m.target) then
        DeleteEntity(m.entity)
        return false
    end

    local pos = GetEntityCoords(m.entity)
    local tPos = GetEntityCoords(m.target)
    local toTarget = tPos - pos
    local dist = #(toTarget)

    if dist <= Config.InterceptDistance then
        AddExplosion(tPos.x, tPos.y, tPos.z, Config.Effects.interceptExplosion.type, Config.Effects.interceptExplosion.damageScale, Config.Effects.interceptExplosion.audible, Config.Effects.interceptExplosion.invisible, 1.0)
        DeleteEntity(m.entity)
        return false
    end

    if GetGameTimer() - m.createdAt > Config.InterceptorLifeMs then
        DeleteEntity(m.entity)
        return false
    end

    local dir = toTarget / dist
    SetEntityVelocity(m.entity, dir.x * Config.InterceptorSpeed, dir.y * Config.InterceptorSpeed, dir.z * Config.InterceptorSpeed)
    SetEntityHeading(m.entity, headingTo(pos, tPos))

    if loadPtfx(Config.Effects.smokePtfx.dict) then
        UseParticleFxAssetNextCall(Config.Effects.smokePtfx.dict)
        StartParticleFxNonLoopedOnEntity(Config.Effects.smokePtfx.name, m.entity, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Effects.smokePtfx.scale, false, false, false)
    end

    return true
end

local function scanAndEngage(battery)
    if not DoesEntityExist(battery.vehicle) then return end
    if battery.missilesLeft <= 0 then return end
    if GetGameTimer() < battery.cooldownUntil then return end

    local vehPos = GetEntityCoords(battery.vehicle)
    local pool = GetGamePool("CVehicle")

    local candidates = {}

    for i = 1, #pool do
        local ent = pool[i]
        local ePos = GetEntityCoords(ent)
        if #(ePos - vehPos) <= Config.RadarRange then
            local threat, speed, dist, approach = isThreat(ent, battery)
            if threat then
                candidates[#candidates + 1] = {
                    entity = ent,
                    score = calcHitChance(speed, dist, approach),
                    dist = dist
                }
            end
        end
    end

    local ppool = GetGamePool("CObject")
    for i = 1, #ppool do
        local obj = ppool[i]
        local mdl = GetEntityModel(obj)
        if mdl == `w_lr_rpg_rocket` or mdl == `w_ex_vehiclemissile_1` then
            local threat, speed, dist, approach = isThreat(obj, battery)
            if threat then
                candidates[#candidates + 1] = {
                    entity = obj,
                    score = calcHitChance(speed, dist, approach) + 0.2,
                    dist = dist
                }
            end
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)

    local engaged = 0
    for i = 1, #candidates do
        if engaged >= Config.MaxTrackedTargets then break end
        local c = candidates[i]
        if c.score >= Config.MinHitChance then
            local vPos = GetEntityCoords(battery.vehicle)
            local tPos = GetEntityCoords(c.entity)
            SetEntityHeading(battery.vehicle, headingTo(vPos, tPos))
            createInterceptor(battery, c.entity)
            battery.missilesLeft = battery.missilesLeft - 1
            battery.cooldownUntil = GetGameTimer() + Config.CooldownMs
            engaged = engaged + 1
        end
    end
end

RegisterNetEvent("patriotaa:client:spawnNetwork", function()
    batteries = {}
    for i = 1, #Config.SpawnPoints do
        spawnBattery(Config.SpawnPoints[i])
    end
end)

RegisterNetEvent("patriotaa:client:toggleByServer", function(state)
    systemEnabled = state == true
end)

RegisterCommand(Config.Commands.toggle, function()
    systemEnabled = not systemEnabled
    TriggerServerEvent("patriotaa:server:setRadarState", systemEnabled)
end)

RegisterCommand(Config.Commands.spawn, function()
    TriggerEvent("patriotaa:client:spawnNetwork")
end)

CreateThread(function()
    while true do
        if systemEnabled and #batteries > 0 then
            for i = 1, #batteries do
                scanAndEngage(batteries[i])
            end
            Wait(Config.ScanIntervalMs)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if #activeMissiles > 0 then
            for i = #activeMissiles, 1, -1 do
                if not stepMissile(activeMissiles[i]) then
                    table.remove(activeMissiles, i)
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    Wait(2000)
    if Config.RadarEnabledByDefault then
        TriggerEvent("patriotaa:client:spawnNetwork")
    end
end)

local QBCore = exports['qb-core']:GetCoreObject()

local missiles = {}
local missileCounter = 0

local function resolveId(idOrData)
    if type(idOrData) == 'table' then
        return idOrData.id or idOrData.args or idOrData.missileId
    end
    return idOrData
end

local function dbg(...)
    if not Config.Debug then return end
    print('[mos2-server]', ...)
end

local function makeMissileId()
    missileCounter = missileCounter + 1
    return missileCounter
end

local function ensureModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    return true
end

local function broadcastState(id)
    if not missiles[id] then return end
    TriggerClientEvent('mos2:client:updateMissileState', -1, id, missiles[id])
end

local function createMissileAtStage(coords, heading, stage)
    local model = stage == 1 and Config.MissileModels.stage1 or stage == 2 and Config.MissileModels.stage2 or Config.MissileModels.complete
    if not ensureModel(model) then return nil end

    local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true, false)
    if not obj or obj == 0 then return nil end

    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    local netId = NetworkGetNetworkIdFromEntity(obj)
    SetNetworkIdExistsOnAllMachines(netId, true)
    return obj, netId
end

local function replaceMissileModel(id, stage)
    local missile = missiles[id]
    if not missile then return end

    local oldEntity = NetworkGetEntityFromNetworkId(missile.netId)
    local coords = missile.coords
    local heading = missile.heading

    local newEntity, newNet = createMissileAtStage(coords, heading, stage)
    if not newEntity then return end

    missile.netId = newNet
    missile.stage = stage
    missile.complete = stage >= 3

    if oldEntity and oldEntity ~= 0 then
        DeleteEntity(oldEntity)
    end

    TriggerClientEvent('mos2:client:updateMissileEntity', -1, id, newNet)
    broadcastState(id)
end

RegisterNetEvent('mos2:server:startCraft', function()
    local src = source
    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local pCoords = GetEntityCoords(ped)
    if #(pCoords - Config.WarehouseCraftPoint) > 6.0 then
        TriggerClientEvent('mos2:client:notify', src, 'يجب أن تكون داخل المستودع للتصنيع.', 'error')
        return
    end

    local id = makeMissileId()
    local spawnCoords = Config.WarehouseCraftPoint + vector3(1.5, 0.0, 0.0)
    local entity, netId = createMissileAtStage(spawnCoords, Config.WarehouseHeading, 1)
    if not entity then
        TriggerClientEvent('mos2:client:notify', src, 'فشل إنشاء هيكل الصاروخ.', 'error')
        return
    end

    missiles[id] = {
        id = id,
        owner = src,
        coords = spawnCoords,
        heading = Config.WarehouseHeading,
        netId = netId,
        stage = 1,
        complete = false,
        programmedRange = nil,
        programmedTarget = nil,
        attachedTruck = nil,
        launched = false
    }

    TriggerClientEvent('mos2:client:runCraftSequence', src, {
        id = id,
        netId = netId,
        coords = spawnCoords
    })

    broadcastState(id)
end)

RegisterNetEvent('mos2:server:cancelCraft', function(idOrData)
    local id = resolveId(idOrData)
    local missile = missiles[id]
    if not missile then return end

    local entity = NetworkGetEntityFromNetworkId(missile.netId)
    if entity and entity ~= 0 then
        DeleteEntity(entity)
    end
    missiles[id] = nil
    TriggerClientEvent('mos2:client:deleteMissile', -1, id)
end)

RegisterNetEvent('mos2:server:setMissileStage', function(idOrData, stage)
    local id = resolveId(idOrData)
    local missile = missiles[id]
    if not missile or missile.launched then return end

    if stage < 2 or stage > 3 then return end
    replaceMissileModel(id, stage)

    if stage == 3 then
        TriggerClientEvent('mos2:client:notify', missile.owner, 'خيار برمجة الصاروخ متاح الآن.', 'success')
    end
end)

RegisterNetEvent('mos2:server:setProgramming', function(idOrData, rangeKm, target)
    local id = resolveId(idOrData)
    local src = source
    local missile = missiles[id]
    if not missile then return end
    if not missile.complete then
        TriggerClientEvent('mos2:client:notify', src, 'أكمل التصنيع أولاً.', 'error')
        return
    end

    rangeKm = tonumber(rangeKm)
    if not rangeKm or rangeKm <= 0 or rangeKm > 1000 then
        TriggerClientEvent('mos2:client:notify', src, 'مدى الطيران غير صالح.', 'error')
        return
    end

    missile.programmedRange = rangeKm
    missile.programmedTarget = {
        x = target.x,
        y = target.y,
        z = target.z,
        label = target.label or 'Custom'
    }

    broadcastState(id)
    TriggerClientEvent('mos2:client:notify', src, ('تمت البرمجة بنجاح: %s كم - %s'):format(rangeKm, missile.programmedTarget.label), 'success')
end)

RegisterNetEvent('mos2:server:spawnTransport', function(idOrData)
    local id = resolveId(idOrData)
    local src = source
    local ped = GetPlayerPed(src)
    local missile = missiles[id]
    if not missile then return end

    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)

    local spawn = vector3(
        coords.x + (forward.x * Config.TransportSpawnOffset.x),
        coords.y + (forward.y * Config.TransportSpawnOffset.x),
        coords.z
    )

    if not ensureModel(Config.TransportTruckModel) then
        TriggerClientEvent('mos2:client:notify', src, 'موديل الشاحنة غير متوفر.', 'error')
        return
    end

    local veh = CreateVehicle(Config.TransportTruckModel, spawn.x, spawn.y, spawn.z, GetEntityHeading(ped) + Config.TransportSpawnOffset.w, true, true)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetVehicleDoorsLocked(veh, 1)

    TriggerClientEvent('mos2:client:spawnTransport', src, netId)
end)

RegisterNetEvent('mos2:server:attachMissile', function(idOrData, vehNetId)
    local id = resolveId(idOrData)
    local missile = missiles[id]
    if not missile then return end

    missile.attachedTruck = vehNetId
    broadcastState(id)
    TriggerClientEvent('mos2:client:syncAttach', -1, id, vehNetId)
end)

RegisterNetEvent('mos2:server:detachMissile', function(idOrData)
    local id = resolveId(idOrData)
    local missile = missiles[id]
    if not missile then return end

    missile.attachedTruck = nil
    broadcastState(id)
    TriggerClientEvent('mos2:client:syncDetach', -1, id)
end)

RegisterNetEvent('mos2:server:moveToLaunchPad', function(idOrData)
    local id = resolveId(idOrData)
    local src = source
    local missile = missiles[id]
    if not missile then return end

    local ent = NetworkGetEntityFromNetworkId(missile.netId)
    if not ent or ent == 0 then return end

    missile.coords = Config.LaunchPad.coords
    missile.heading = Config.LaunchPad.heading
    missile.attachedTruck = nil

    SetEntityCoords(ent, Config.LaunchPad.coords.x, Config.LaunchPad.coords.y, Config.LaunchPad.coords.z, false, false, false, false)
    SetEntityHeading(ent, Config.LaunchPad.heading)
    FreezeEntityPosition(ent, true)

    broadcastState(id)
    TriggerClientEvent('mos2:client:syncDetach', -1, id)
    TriggerClientEvent('mos2:client:notify', src, 'تم نقل الصاروخ إلى منصة الإطلاق.', 'success')
end)

local function runLaunchMotion(id)
    local missile = missiles[id]
    if not missile then return end

    local ent = NetworkGetEntityFromNetworkId(missile.netId)
    if not ent or ent == 0 then return end

    local origin = GetEntityCoords(ent)
    local target = vector3(missile.programmedTarget.x, missile.programmedTarget.y, missile.programmedTarget.z)

    FreezeEntityPosition(ent, false)

    local tick = Config.Flight.tick

    -- المرحلة 1: إقلاع عمودي متسارع
    local phaseEnd = GetGameTimer() + Config.Flight.verticalTime
    local startZ = origin.z
    while GetGameTimer() < phaseEnd do
        local t = 1.0 - ((phaseEnd - GetGameTimer()) / Config.Flight.verticalTime)
        local eased = t * t
        local current = vector3(origin.x, origin.y, startZ + (Config.Flight.maxVerticalBoost * eased))
        SetEntityCoordsNoOffset(ent, current.x, current.y, current.z, true, true, true)
        SetEntityRotation(ent, 0.0, 0.0, missile.heading, 2, true)

        TriggerClientEvent('mos2:client:updateFlightTransform', -1, id, { x = current.x, y = current.y, z = current.z }, { x = 0.0, y = 0.0, z = missile.heading })
        Wait(tick)
    end

    local current = GetEntityCoords(ent)

    -- المرحلة 2: ميلان بسيط للأمام
    phaseEnd = GetGameTimer() + Config.Flight.tiltTime
    while GetGameTimer() < phaseEnd do
        local t = 1.0 - ((phaseEnd - GetGameTimer()) / Config.Flight.tiltTime)
        local tilt = 35.0 * t
        local step = vector3(current.x, current.y + (t * 1.0), current.z + (Config.Flight.tiltHeightGain * t))

        SetEntityCoordsNoOffset(ent, step.x, step.y, step.z, true, true, true)
        SetEntityRotation(ent, -tilt, 0.0, missile.heading, 2, true)

        TriggerClientEvent('mos2:client:updateFlightTransform', -1, id, { x = step.x, y = step.y, z = step.z }, { x = -tilt, y = 0.0, z = missile.heading })
        Wait(tick)
    end

    local arcStart = GetEntityCoords(ent)

    -- المرحلة 3: انحناء باتجاه الهدف
    phaseEnd = GetGameTimer() + Config.Flight.cruiseTime
    while GetGameTimer() < phaseEnd do
        local t = 1.0 - ((phaseEnd - GetGameTimer()) / Config.Flight.cruiseTime)
        local base = vector3(
            arcStart.x + (target.x - arcStart.x) * t,
            arcStart.y + (target.y - arcStart.y) * t,
            arcStart.z + (target.z - arcStart.z) * t
        )

        local heightBoost = math.sin(t * math.pi) * Config.Flight.arcHeight
        local curve = vector3(base.x, base.y, base.z + heightBoost)

        local aheadT = math.min(1.0, t + 0.02)
        local aheadBase = vector3(
            arcStart.x + (target.x - arcStart.x) * aheadT,
            arcStart.y + (target.y - arcStart.y) * aheadT,
            arcStart.z + (target.z - arcStart.z) * aheadT
        )
        local aheadCurve = vector3(aheadBase.x, aheadBase.y, aheadBase.z + math.sin(aheadT * math.pi) * Config.Flight.arcHeight)

        local dir = (aheadCurve - curve)
        local yaw = math.deg(math.atan2(dir.y, dir.x)) - 90.0
        local pitch = -math.deg(math.atan2(dir.z, math.sqrt((dir.x * dir.x) + (dir.y * dir.y))))

        SetEntityCoordsNoOffset(ent, curve.x, curve.y, curve.z, true, true, true)
        SetEntityRotation(ent, pitch, 0.0, yaw, 2, true)

        TriggerClientEvent('mos2:client:updateFlightTransform', -1, id, { x = curve.x, y = curve.y, z = curve.z }, { x = pitch, y = 0.0, z = yaw })
        Wait(tick)
    end

    local impact = target
    TriggerClientEvent('mos2:client:impact', -1, id, { x = impact.x, y = impact.y, z = impact.z })

    DeleteEntity(ent)
    missiles[id] = nil
end

RegisterNetEvent('mos2:server:requestLaunch', function(idOrData)
    local id = resolveId(idOrData)
    local src = source
    local missile = missiles[id]
    if not missile then return end

    if not missile.complete or not missile.programmedTarget then
        TriggerClientEvent('mos2:client:notify', src, 'الصاروخ غير جاهز للإطلاق.', 'error')
        return
    end

    missile.launched = true
    missile.attachedTruck = nil
    broadcastState(id)

    TriggerClientEvent('mos2:client:launchCountdown', -1, id)

    SetTimeout(3000, function()
        TriggerClientEvent('mos2:client:launchFx', -1, id)
        runLaunchMotion(id)
    end)
end)

RegisterNetEvent('mos2:server:requestStateSync', function()
    local src = source
    TriggerClientEvent('mos2:client:fullState', src, missiles)
end)

RegisterNetEvent('mos2:server:requestTruckForOwner', function()
    local src = source
    local targetId
    for id, missile in pairs(missiles) do
        if missile.owner == src and missile.complete and not missile.launched then
            targetId = id
        end
    end

    if not targetId then
        TriggerClientEvent('mos2:client:notify', src, 'لا يوجد صاروخ مكتمل للتجهيز.', 'error')
        return
    end

    TriggerClientEvent('mos2:client:requestTruck', src, targetId)
end)

QBCore.Commands.Add('missiletruck', 'طلب شاحنة نقل للصاروخ الحالي', {}, false, function(src)
    local targetId
    for id, missile in pairs(missiles) do
        if missile.owner == src and missile.complete and not missile.launched then
            targetId = id
        end
    end

    if not targetId then
        TriggerClientEvent('mos2:client:notify', src, 'لا يوجد صاروخ مكتمل للتجهيز.', 'error')
        return
    end

    TriggerClientEvent('mos2:client:requestTruck', src, targetId)
end)

dbg('server script loaded')

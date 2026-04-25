local QBCore = exports['qb-core']:GetCoreObject()

local missiles = {}
local carryingMissile = nil
local runningFlightFx = {}

local function dbg(...)
    if not Config.Debug then return end
    print('[mos2]', ...)
end

local function requestModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end
end

local function requestPtfx(dict)
    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(0)
        end
    end
end

local function makeMissileTarget(id)
    local missileData = missiles[id]
    if not missileData or not missileData.entity or not DoesEntityExist(missileData.entity) then return end

    exports['qb-target']:AddTargetEntity(missileData.entity, {
        options = {
            {
                icon = 'fas fa-hands',
                label = 'حمل الصاروخ',
                type = 'client',
                event = 'mos2:client:carryMissile',
                args = id,
                canInteract = function()
                    return not carryingMissile and not missileData.attachedTruck and not missileData.launched
                end
            },
            {
                icon = 'fas fa-truck-loading',
                label = 'تحميله على مركبة',
                type = 'client',
                event = 'mos2:client:loadToVehicle',
                args = id,
                canInteract = function()
                    return not missileData.attachedTruck and not missileData.launched
                end
            },
            {
                icon = 'fas fa-unlink',
                label = 'فك التثبيت',
                type = 'server',
                event = 'mos2:server:detachMissile',
                args = id,
                canInteract = function()
                    return missileData.attachedTruck ~= nil and not missileData.launched
                end
            },
            {
                icon = 'fas fa-crosshairs',
                label = 'برمجة الهدف',
                type = 'client',
                event = 'mos2:client:openProgramming',
                args = id,
                canInteract = function()
                    return missileData.complete and not missileData.launched
                end
            },
            {
                icon = 'fas fa-dolly',
                label = 'نقل للمنصة',
                type = 'server',
                event = 'mos2:server:moveToLaunchPad',
                args = id,
                canInteract = function()
                    return missileData.complete and not missileData.launched
                end
            },
            {
                icon = 'fas fa-rocket',
                label = 'إطلاق',
                type = 'server',
                event = 'mos2:server:requestLaunch',
                args = id,
                canInteract = function()
                    return missileData.complete and missileData.programmedTarget ~= nil and not missileData.launched
                end
            }
        },
        distance = 2.7
    })
end

local function updateMissileEntity(id, netId)
    if not missiles[id] then missiles[id] = {} end
    missiles[id].netId = netId
    missiles[id].entity = NetToObj(netId)

    CreateThread(function()
        local timeout = 0
        while (not missiles[id].entity or not DoesEntityExist(missiles[id].entity)) and timeout < 120 do
            missiles[id].entity = NetToObj(netId)
            timeout = timeout + 1
            Wait(100)
        end

        if missiles[id].entity and DoesEntityExist(missiles[id].entity) then
            makeMissileTarget(id)
        end
    end)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function vecLerp(a, b, t)
    return vector3(lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t))
end

local function playAttachAnim(text)
    QBCore.Functions.Progressbar('mos2_action', text, 4500, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'amb@world_human_welding@male@base',
        anim = 'base',
        flags = 49
    }, {}, {}, function()
        ClearPedTasks(PlayerPedId())
    end, function()
        ClearPedTasks(PlayerPedId())
    end)
end

CreateThread(function()
    exports['qb-target']:AddBoxZone('mos2_missile_craft_zone', Config.WarehouseCraftPoint, 2.2, 2.2, {
        name = 'mos2_missile_craft_zone',
        heading = Config.WarehouseHeading,
        debugPoly = false,
        minZ = Config.WarehouseCraftPoint.z - 1.2,
        maxZ = Config.WarehouseCraftPoint.z + 1.5,
    }, {
        options = {
            {
                icon = 'fas fa-rocket',
                label = 'ابدأ تصنيع صاروخ',
                type = 'server',
                event = 'mos2:server:startCraft'
            },
            {
                icon = 'fas fa-truck',
                label = 'طلب شاحنة نقل',
                type = 'server',
                event = 'mos2:server:requestTruckForOwner'
            }
        },
        distance = 2.5
    })
end)

RegisterNetEvent('mos2:client:runCraftSequence', function(craftData)
    local id = craftData.id
    requestModel(Config.MissileModels.stage1)

    local ped = PlayerPedId()
    local coords = vector3(craftData.coords.x, craftData.coords.y, craftData.coords.z)

    TaskTurnPedToFaceCoord(ped, coords.x, coords.y, coords.z, 1000)
    Wait(250)

    QBCore.Functions.Progressbar('mos2_craft_' .. id, 'جاري تصنيع الصاروخ...', Config.StageDurations.total, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mini@repair',
        anim = 'fixing_a_ped',
        flags = 49
    }, {}, {}, function()
        ClearPedTasks(ped)
        QBCore.Functions.Notify('اكتمل تصنيع الصاروخ. الآن يمكنك البرمجة والنقل.', 'success')
    end, function()
        ClearPedTasks(ped)
        TriggerServerEvent('mos2:server:cancelCraft', id)
        QBCore.Functions.Notify('تم إلغاء التصنيع.', 'error')
    end)

    updateMissileEntity(id, craftData.netId)

    CreateThread(function()
        Wait(Config.StageDurations.stage1)
        TriggerServerEvent('mos2:server:setMissileStage', id, 2)
        Wait(Config.StageDurations.stage2)
        TriggerServerEvent('mos2:server:setMissileStage', id, 3)
    end)
end)

RegisterNetEvent('mos2:client:updateMissileEntity', function(id, netId)
    updateMissileEntity(id, netId)
end)

RegisterNetEvent('mos2:client:updateMissileState', function(id, state)
    missiles[id] = missiles[id] or {}
    for k, v in pairs(state) do
        missiles[id][k] = v
    end

    if state.netId then
        updateMissileEntity(id, state.netId)
    end
end)

RegisterNetEvent('mos2:client:deleteMissile', function(id)
    local missileData = missiles[id]
    if missileData and missileData.entity and DoesEntityExist(missileData.entity) then
        DeleteEntity(missileData.entity)
    end
    missiles[id] = nil
end)

local function resolveId(idOrData)
    if type(idOrData) == 'table' then
        return idOrData.id or idOrData.args or idOrData.missileId
    end
    return idOrData
end

RegisterNetEvent('mos2:client:carryMissile', function(idOrData)
    local id = resolveId(idOrData)
    local missileData = missiles[id]
    if not missileData or not missileData.entity or not DoesEntityExist(missileData.entity) then return end

    carryingMissile = id
    playAttachAnim('جاري حمل الصاروخ...')

    AttachEntityToEntity(missileData.entity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.25, 0.02, -0.15, 180.0, 90.0, 90.0, false, false, false, false, 2, true)
end)

RegisterNetEvent('mos2:client:loadToVehicle', function(idOrData)
    local id = resolveId(idOrData)
    local missileData = missiles[id]
    if not missileData or not missileData.entity or not DoesEntityExist(missileData.entity) then return end

    local veh = QBCore.Functions.GetClosestVehicle()
    if veh == 0 or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(veh)) > 6.0 then
        QBCore.Functions.Notify('لا توجد مركبة مناسبة قريبة.', 'error')
        return
    end

    playAttachAnim('تثبيت الصاروخ على المركبة...')
    TriggerServerEvent('mos2:server:attachMissile', id, VehToNet(veh))

    if carryingMissile == id then
        DetachEntity(missileData.entity, true, true)
        carryingMissile = nil
    end
end)

RegisterNetEvent('mos2:client:syncAttach', function(id, vehicleNetId)
    local missileData = missiles[id]
    if not missileData then return end

    local vehicle = NetToVeh(vehicleNetId)
    local missile = missileData.entity or NetToObj(missileData.netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not missile or not DoesEntityExist(missile) then return end

    DetachEntity(missile, true, true)
    AttachEntityToEntity(missile, vehicle, 0, 0.0, -3.2, 1.4, 0.0, 0.0, 90.0, false, false, false, false, 2, true)
    FreezeEntityPosition(missile, true)
end)

RegisterNetEvent('mos2:client:syncDetach', function(id)
    local missileData = missiles[id]
    if not missileData then return end

    local missile = missileData.entity or NetToObj(missileData.netId)
    if missile and DoesEntityExist(missile) then
        FreezeEntityPosition(missile, false)
        DetachEntity(missile, true, true)
    end
end)

RegisterNetEvent('mos2:client:openProgramming', function(idOrData)
    local id = resolveId(idOrData)
    local missileData = missiles[id]
    if not missileData then return end

    local menu = {
        {
            header = 'برمجة الصاروخ',
            isMenuHeader = true
        },
        {
            header = 'تحديد هدف عبر Waypoint',
            txt = 'ضع علامة على الخريطة ثم اختر هذا الخيار.',
            params = {
                event = 'mos2:client:setTargetFromWaypoint',
                args = { id = id }
            }
        }
    }

    for index, target in ipairs(Config.PredefinedTargets) do
        menu[#menu + 1] = {
            header = target.label,
            txt = ('إحداثيات: %.2f %.2f %.2f'):format(target.coords.x, target.coords.y, target.coords.z),
            params = {
                event = 'mos2:client:setPredefinedTarget',
                args = { id = id, targetIndex = index }
            }
        }
    end

    menu[#menu + 1] = {
        header = 'إغلاق',
        params = { event = '' }
    }

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('mos2:client:setTargetFromWaypoint', function(data)
    local id = data.id
    local input = exports['qb-input']:ShowInput({
        header = 'إدخال مدى الطيران (كم)',
        submitText = 'حفظ',
        inputs = {
            {
                text = 'المدى بالكيلومتر',
                name = 'range',
                type = 'number',
                isRequired = true
            }
        }
    })

    if not input or not input.range then return end

    local blip = GetFirstBlipInfoId(8)
    if blip == 0 then
        QBCore.Functions.Notify('ضع Waypoint أولاً على الخريطة.', 'error')
        return
    end

    local coords = GetBlipInfoIdCoord(blip)
    TriggerServerEvent('mos2:server:setProgramming', id, tonumber(input.range), {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        label = 'Waypoint'
    })
end)

RegisterNetEvent('mos2:client:setPredefinedTarget', function(data)
    local id = data.id
    local target = Config.PredefinedTargets[data.targetIndex]
    if not target then return end

    local input = exports['qb-input']:ShowInput({
        header = ('مدى الطيران نحو: %s'):format(target.label),
        submitText = 'حفظ',
        inputs = {
            {
                text = 'المدى بالكيلومتر',
                name = 'range',
                type = 'number',
                isRequired = true
            }
        }
    })

    if not input or not input.range then return end

    TriggerServerEvent('mos2:server:setProgramming', id, tonumber(input.range), {
        x = target.coords.x,
        y = target.coords.y,
        z = target.coords.z,
        label = target.label
    })
end)

RegisterNetEvent('mos2:client:spawnTransport', function(netId)
    local veh = NetToVeh(netId)
    if veh ~= 0 and DoesEntityExist(veh) then
        SetVehicleOnGroundProperly(veh)
        QBCore.Functions.Notify('تم طلب شاحنة النقل.', 'success')
    end
end)

RegisterNetEvent('mos2:client:launchCountdown', function(id)
    local missileData = missiles[id]
    if not missileData then return end

    for i = 3, 1, -1 do
        QBCore.Functions.Notify(('الإطلاق خلال %s ...'):format(i), 'primary', 900)
        Wait(1000)
    end
end)

RegisterNetEvent('mos2:client:launchFx', function(id)
    local missileData = missiles[id]
    if not missileData or not missileData.entity or not DoesEntityExist(missileData.entity) then return end

    local coords = GetEntityCoords(missileData.entity)
    requestPtfx(Config.Particles.launchDict)
    UseParticleFxAssetNextCall(Config.Particles.launchDict)

    local fx = StartParticleFxLoopedAtCoord(Config.Particles.launchName, coords.x, coords.y, coords.z - 0.7, 0.0, 0.0, 0.0, 2.1, false, false, false, false)
    runningFlightFx[id] = fx

    PlaySoundFromCoord(-1, Config.Sounds.launch, coords.x, coords.y, coords.z, Config.Sounds.launchRef, false, 0, false)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.45)

    CreateThread(function()
        local endAt = GetGameTimer() + 5000
        while GetGameTimer() < endAt do
            Wait(0)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
        end
    end)
end)

RegisterNetEvent('mos2:client:updateFlightTransform', function(id, coords, rot)
    local missileData = missiles[id]
    if not missileData then return end

    local missile = missileData.entity or NetToObj(missileData.netId)
    if not missile or not DoesEntityExist(missile) then return end

    SetEntityCoordsNoOffset(missile, coords.x, coords.y, coords.z, true, true, true)
    SetEntityRotation(missile, rot.x, rot.y, rot.z, 2, true)

    if GetGameTimer() % 400 < 70 then
        PlaySoundFromCoord(-1, Config.Sounds.flight, coords.x, coords.y, coords.z, Config.Sounds.flightRef, false, 0, false)
    end
end)

RegisterNetEvent('mos2:client:impact', function(id, coords)
    local missileData = missiles[id]
    if missileData and missileData.entity and DoesEntityExist(missileData.entity) then
        DeleteEntity(missileData.entity)
    end

    AddExplosion(coords.x, coords.y, coords.z, 59, 8.5, true, false, 2.0)

    requestPtfx(Config.Particles.impactDict)
    UseParticleFxAssetNextCall(Config.Particles.impactDict)
    StartParticleFxNonLoopedAtCoord(Config.Particles.impactName, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 3.5, false, false, false)

    PlaySoundFromCoord(-1, Config.Sounds.impact, coords.x, coords.y, coords.z, Config.Sounds.impactRef, false, 0, false)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.4)
    StartScreenEffect('Rampage', 1400, false)

    if runningFlightFx[id] then
        StopParticleFxLooped(runningFlightFx[id], false)
        runningFlightFx[id] = nil
    end
end)

RegisterNetEvent('mos2:client:requestTruck', function(id)
    TriggerServerEvent('mos2:server:spawnTransport', id)
end)

RegisterNetEvent('mos2:client:notify', function(message, msgType)
    QBCore.Functions.Notify(message, msgType or 'primary')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('mos2:server:requestStateSync')
end)

RegisterNetEvent('mos2:client:fullState', function(state)
    missiles = {}
    for id, missileData in pairs(state) do
        missiles[id] = missileData
        if missileData.netId then
            updateMissileEntity(id, missileData.netId)
        end
    end
end)

dbg('client script loaded')

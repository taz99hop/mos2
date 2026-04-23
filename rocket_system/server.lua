local QBCore = exports['qb-core']:GetCoreObject()

local LaunchPads = {}
local NextPadId = 1

local function syncPads(target)
    TriggerClientEvent('rocket_system:client:syncPads', target or -1, LaunchPads)
end

local function removePad(src, id)
    id = tonumber(id)
    if not id or not LaunchPads[id] then
        TriggerClientEvent('QBCore:Notify', src, _L('no_pad_found'), 'error')
        return
    end

    LaunchPads[id] = nil
    syncPads()
    TriggerClientEvent('QBCore:Notify', src, _L('pad_removed', id), 'success')
end

RegisterNetEvent('rocket_system:server:createPad', function(coords, heading)
    local src = source

    local id = NextPadId
    NextPadId = NextPadId + 1

    LaunchPads[id] = {
        id = id,
        coords = coords,
        heading = heading,
        fuel = Config.PadDefaults.fuel,
        ammo = Config.PadDefaults.ammo,
        armAngle = Config.PadDefaults.armAngle,
        raised = Config.PadDefaults.raised,
        cooldownEnd = 0
    }

    syncPads()
    TriggerClientEvent('QBCore:Notify', src, _L('pad_created', id), 'success')
end)

RegisterNetEvent('rocket_system:server:removePad', function(id)
    removePad(source, id)
end)

RegisterNetEvent('rocket_system:server:updatePadState', function(id, payload)
    local pad = LaunchPads[id]
    if not pad then
        return
    end

    if payload.armAngle then
        pad.armAngle = payload.armAngle
    end

    if payload.raised ~= nil then
        pad.raised = payload.raised
    end

    syncPads()
end)

RegisterNetEvent('rocket_system:server:refillPad', function(id)
    local src = source
    local pad = LaunchPads[id]
    if not pad then
        return
    end

    pad.fuel = Config.PadDefaults.fuel
    pad.ammo = Config.PadDefaults.ammo
    pad.cooldownEnd = 0

    syncPads()
    TriggerClientEvent('QBCore:Notify', src, _L('reloaded'), 'success')
end)

QBCore.Functions.CreateCallback('rocket_system:server:getPadStatus', function(_, cb, id)
    cb(LaunchPads[id])
end)

QBCore.Functions.CreateCallback('rocket_system:server:getAllPads', function(_, cb)
    cb(LaunchPads)
end)

QBCore.Functions.CreateCallback('rocket_system:server:canFire', function(source, cb, id)
    local pad = LaunchPads[id]
    if not pad then
        cb(false, 'no_pad_found')
        return
    end

    local now = os.time()
    if pad.cooldownEnd > now then
        cb(false, 'cooldown_active', pad.cooldownEnd - now)
        return
    end

    if pad.fuel < Config.Fire.FuelPerShot then
        cb(false, 'not_enough_fuel')
        return
    end

    if pad.ammo <= 0 then
        cb(false, 'not_enough_ammo')
        return
    end

    pad.fuel = pad.fuel - Config.Fire.FuelPerShot
    pad.ammo = pad.ammo - 1
    pad.cooldownEnd = now + Config.Rocket.Cooldown

    syncPads()
    cb(true, pad)
    TriggerClientEvent('rocket_system:client:launchRocket', -1, id, pad)
    TriggerClientEvent('QBCore:Notify', source, _L('rocket_fired'), 'success')
end)

QBCore.Commands.Add('rocketcreatepad', 'Create rocket launch pad', {}, false, function(source)
    TriggerClientEvent('rocket_system:client:createPadAtPlayer', source)
end)

QBCore.Commands.Add('rocketremovepad', 'Remove rocket launch pad by id', {
    { name = 'id', help = 'Pad ID' }
}, true, function(source, args)
    removePad(source, tonumber(args[1]))
end)

QBCore.Commands.Add('rocketstatus', 'Show rocket system status', {}, false, function(source)
    TriggerClientEvent('rocket_system:client:showStatus', source)
end)

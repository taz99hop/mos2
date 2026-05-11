local radarState = {}

local function getIdentifier(src)
    local ids = GetPlayerIdentifiers(src)
    return ids[1] or ("src:" .. tostring(src))
end

RegisterNetEvent("patriotaa:server:setRadarState", function(enabled)
    local src = source
    local id = getIdentifier(src)
    radarState[id] = enabled == true
end)

QBCore = QBCore or exports['qb-core']:GetCoreObject()

QBCore.Commands.Add(Config.Commands.toggle, "تشغيل/إطفاء رادار patriotaa", {}, false, function(source)
    local id = getIdentifier(source)
    local newState = not radarState[id]
    radarState[id] = newState
    TriggerClientEvent("patriotaa:client:toggleByServer", source, newState)
end)

QBCore.Commands.Add(Config.Commands.spawn, "Spawn 3 patriotaa داخل لوس سانتوس", {}, false, function(source)
    TriggerClientEvent("patriotaa:client:spawnNetwork", source)
end)

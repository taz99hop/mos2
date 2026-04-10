local launchCooldown = {}

local function computeFlightTime(startPos, targetPos)
    local distance = #(startPos - targetPos)
    local cruiseTime = distance / Config.Missile.cruiseSpeed
    return Config.Missile.ascentDuration + cruiseTime
end

RegisterNetEvent('missile:server:requestLaunch', function(padIndex, target)
    local src = source

    if type(padIndex) ~= 'number' or not Config.LaunchPads[padIndex] then
        return
    end

    if type(target) ~= 'vector3' and type(target) ~= 'table' then
        return
    end

    local now = GetGameTimer()
    local untilTime = launchCooldown[padIndex] or 0
    if now < untilTime then
        TriggerClientEvent('QBCore:Notify', src, 'المنصة في حالة إعادة تهيئة.', 'error')
        return
    end

    local padData = Config.LaunchPads[padIndex]
    local start = vec3(
        padData.coords.x + Config.Missile.spawnOffset.x,
        padData.coords.y + Config.Missile.spawnOffset.y,
        padData.coords.z + Config.Missile.spawnOffset.z
    )

    local targetPos = vec3(target.x + 0.0, target.y + 0.0, target.z + 0.0)
    local missionId = ('%d-%d-%d'):format(src, padIndex, now)
    local totalTime = computeFlightTime(start, targetPos)

    launchCooldown[padIndex] = now + Config.Server.launchCooldownMs

    TriggerClientEvent('missile:client:syncLaunch', -1, {
        id = missionId,
        padIndex = padIndex,
        source = src,
        start = { x = start.x, y = start.y, z = start.z },
        target = { x = targetPos.x, y = targetPos.y, z = targetPos.z },
        ascentDuration = Config.Missile.ascentDuration,
        totalTime = totalTime
    })

    SetTimeout(math.floor(totalTime * 1000), function()
        TriggerClientEvent('missile:client:syncImpact', -1, {
            x = targetPos.x,
            y = targetPos.y,
            z = targetPos.z
        })
    end)
end)

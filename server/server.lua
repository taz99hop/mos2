local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}


local function notify(src, msg, ntype)
    TriggerClientEvent('mos2_missile:client:notify', src, msg, ntype or 'primary')
end

local function isAllowedJob(player)
    if not Config.JobLocked then
        return true
    end

    local job = player.PlayerData.job
    if not job or not job.name then
        return false
    end

    local minGrade = Config.AllowedJobs[job.name]
    if minGrade == nil then
        return false
    end

    return (job.grade.level or 0) >= minGrade
end

local function hasLaunchCard(player)
    if not Config.RequireLaunchCard then
        return true
    end

    local item = player.Functions.GetItemByName(Config.LaunchCardItem)
    return item ~= nil
end

local function normalizeTarget(rawTarget)
    if rawTarget == nil then
        return nil
    end

    -- Handles table payloads from NUI/client events
    if type(rawTarget) == 'table' then
        local x = tonumber(rawTarget.x or rawTarget[1])
        local y = tonumber(rawTarget.y or rawTarget[2])
        local z = tonumber(rawTarget.z or rawTarget[3])

        if x and y and z then
            return { x = x, y = y, z = z }
        end
    end

    -- Handles vector3 userdata cases
    local okX, x = pcall(function() return tonumber(rawTarget.x) end)
    local okY, y = pcall(function() return tonumber(rawTarget.y) end)
    local okZ, z = pcall(function() return tonumber(rawTarget.z) end)
    if okX and okY and okZ and x and y and z then
        return { x = x, y = y, z = z }
    end

    return nil
end

RegisterNetEvent('mos2_missile:server:requestLaunch', function(payload)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if type(payload) ~= 'table' then
        notify(src, 'بيانات إطلاق غير صالحة.', 'error')
        return
    end

    local target = normalizeTarget(payload.target)
    if not target then
        notify(src, 'بيانات إطلاق غير صالحة.', 'error')
        return
    end

    if not isAllowedJob(player) then
        notify(src, 'غير مصرح لك باستخدام نظام الإطلاق.', 'error')
        return
    end

    if not hasLaunchCard(player) then
        notify(src, 'تحتاج بطاقة إطلاق.', 'error')
        return
    end

    local now = os.time()
    local nextReady = cooldowns[src] or 0
    if nextReady > now then
        notify(src, ('النظام في تبريد: %d ثانية.'):format(nextReady - now), 'error')
        return
    end

    local missiles = tonumber(payload.missiles) or Config.DefaultMissileCount
    missiles = math.max(Config.MinMissiles, math.min(Config.MaxMissiles, missiles))

    cooldowns[src] = now + Config.CooldownSeconds
    TriggerClientEvent('mos2_missile:client:setCooldown', src, Config.CooldownSeconds)

    TriggerClientEvent('mos2_missile:client:launchApproved', src, {
        missiles = missiles,
        target = target,
        spread = Config.SpreadRadius,
        delay = Config.MissileDelay
    })

    local citizenId = player.PlayerData.citizenid or 'unknown'
    print(('[mos2_missile] %s launched %d missiles at %.2f %.2f %.2f'):format(
        citizenId,
        missiles,
        target.x,
        target.y,
        target.z
    ))
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

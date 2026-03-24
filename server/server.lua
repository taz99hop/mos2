local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}

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

RegisterNetEvent('mos2_missile:server:requestLaunch', function(payload)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    if type(payload) ~= 'table' or type(payload.target) ~= 'table' then
        TriggerClientEvent('QBCore:Notify', src, 'بيانات إطلاق غير صالحة.', 'error')
        return
    end

    if not isAllowedJob(player) then
        TriggerClientEvent('QBCore:Notify', src, 'غير مصرح لك باستخدام نظام الإطلاق.', 'error')
        return
    end

    if not hasLaunchCard(player) then
        TriggerClientEvent('QBCore:Notify', src, 'تحتاج بطاقة إطلاق.', 'error')
        return
    end

    local now = os.time()
    local nextReady = cooldowns[src] or 0
    if nextReady > now then
        TriggerClientEvent('QBCore:Notify', src, ('النظام في تبريد: %d ثانية.'):format(nextReady - now), 'error')
        return
    end

    local missiles = tonumber(payload.missiles) or Config.DefaultMissileCount
    missiles = math.max(Config.MinMissiles, math.min(Config.MaxMissiles, missiles))

    cooldowns[src] = now + Config.CooldownSeconds
    TriggerClientEvent('mos2_missile:client:setCooldown', src, Config.CooldownSeconds)

    TriggerClientEvent('mos2_missile:client:launchApproved', src, {
        missiles = missiles,
        target = {
            x = tonumber(payload.target.x) or 0.0,
            y = tonumber(payload.target.y) or 0.0,
            z = tonumber(payload.target.z) or 0.0
        },
        spread = Config.SpreadRadius,
        delay = Config.MissileDelay
    })

    local citizenId = player.PlayerData.citizenid or 'unknown'
    print(('[mos2_missile] %s launched %d missiles at %.2f %.2f %.2f'):format(
        citizenId,
        missiles,
        tonumber(payload.target.x) or 0.0,
        tonumber(payload.target.y) or 0.0,
        tonumber(payload.target.z) or 0.0
    ))
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

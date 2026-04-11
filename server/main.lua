local QBCore = exports['qb-core']:GetCoreObject()

local MissileCooldownAt = 0
local HeatLevel = 0
local ZoneStates = {}
local LastAnnouncement = 0
local TrackedWanted = {}

for _, zone in ipairs(Config.Zones) do
    ZoneStates[zone.id] = { owner = 'neutral', contested = false }
end

local function logDebug(...)
    if Config.Debug then
        print('[RESISTANCE]', ...)
    end
end

local function getPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

local function validToken(token)
    return token and token == Config.Security.ServerEventToken
end

local function hasJobAndRank(player, minRank)
    if not player then return false end
    if player.PlayerData.job.name ~= Config.JobName then return false end
    local rank = Resistance.GetGradeName(player.PlayerData)
    if not rank then return false end
    if not minRank then return true, rank end
    return Resistance.HasMinRank(rank, minRank), rank
end

local function notify(src, msg, t)
    TriggerClientEvent('resistance:client:notify', src, msg, t or 'primary')
end

local function broadcast(msg, t)
    TriggerClientEvent('resistance:client:notify', -1, msg, t or 'primary')
end

local function getHeatName(value)
    local th = Config.Heat.Thresholds
    if value >= th.emergency then return 'emergency' end
    if value >= th.high then return 'high' end
    if value >= th.medium then return 'medium' end
    return 'low'
end

local function updateHeat(amount, reason)
    HeatLevel = math.max(0, HeatLevel + amount)
    local levelName = getHeatName(HeatLevel)
    local label = Config.Heat.LabelByLevel[levelName]
    TriggerClientEvent('resistance:client:updateHeat', -1, HeatLevel, label)
    if reason then
        logDebug(('Heat +%s (%s), current=%s'):format(amount, reason, HeatLevel))
    end
end

CreateThread(function()
    while true do
        Wait(Config.Heat.DecayIntervalSeconds * 1000)
        if HeatLevel > 0 then
            HeatLevel = math.max(0, HeatLevel - Config.Heat.DecayAmount)
            local label = Config.Heat.LabelByLevel[getHeatName(HeatLevel)]
            TriggerClientEvent('resistance:client:updateHeat', -1, HeatLevel, label)
        end
    end
end)

RegisterNetEvent('resistance:server:requestState', function(token)
    local src = source
    if not validToken(token) then return end
    local label = Config.Heat.LabelByLevel[getHeatName(HeatLevel)]
    TriggerClientEvent('resistance:client:updateHeat', src, HeatLevel, label)
end)

RegisterNetEvent('resistance:server:craftRecipe', function(payload)
    local src = source
    if type(payload) ~= 'table' or not validToken(payload.token) then return end

    local player = getPlayer(src)
    local ok, rank = hasJobAndRank(player)
    if not ok then return end

    local station = Config.ManufacturingStations[payload.stationId]
    if not station or not Resistance.HasAccessByMap(rank, station.allowedRanks) then
        return notify(src, 'ليس لديك صلاحية للتصنيع هنا.', 'error')
    end

    local recipe
    for _, entry in ipairs(station.recipes) do
        if entry.id == payload.recipeId then
            recipe = entry
            break
        end
    end

    if not recipe then
        return notify(src, 'وصفة تصنيع غير صالحة.', 'error')
    end

    for item, amount in pairs(recipe.requirements) do
        local hasItem = player.Functions.GetItemByName(item)
        if not hasItem or hasItem.amount < amount then
            return notify(src, ('المواد ناقصة: %s'):format(item), 'error')
        end
    end

    for item, amount in pairs(recipe.requirements) do
        player.Functions.RemoveItem(item, amount)
    end

    player.Functions.AddItem(recipe.output.item, recipe.output.amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[recipe.output.item], 'add', recipe.output.amount)
    notify(src, ('تم تصنيع %s بنجاح.'):format(recipe.label), 'success')

    updateHeat(recipe.heat or 0, ('craft:%s'):format(recipe.id))
end)

RegisterNetEvent('resistance:server:launchMissile', function(payload)
    local src = source
    if type(payload) ~= 'table' or not validToken(payload.token) then return end

    local player = getPlayer(src)
    local allowed, rank = hasJobAndRank(player, Config.LeaderGradeName)
    if not allowed or rank ~= Config.LeaderGradeName then
        return notify(src, 'فقط القائد يمكنه إطلاق الصواريخ.', 'error')
    end

    local missileData = Config.Missile.Types[payload.mtype]
    if not missileData then
        return notify(src, 'نوع الصاروخ غير متاح.', 'error')
    end

    local now = os.time()
    if now < MissileCooldownAt then
        return notify(src, ('المنصة تبرد.. انتظر %s ثانية.'):format(MissileCooldownAt - now), 'error')
    end

    local coords = payload.coords
    if type(coords) ~= 'vector3' then
        return notify(src, 'إحداثيات غير صحيحة.', 'error')
    end

    local origin = Config.Missile.LaunchConsole
    if #(coords - origin) > Config.Missile.LaunchRadius then
        return notify(src, 'الموقع خارج مدى المنصة.', 'error')
    end

    local required = player.Functions.GetItemByName(missileData.requiredItem)
    if not required or required.amount < 1 then
        return notify(src, ('تحتاج: %s'):format(missileData.requiredItem), 'error')
    end

    player.Functions.RemoveItem(missileData.requiredItem, 1)
    MissileCooldownAt = now + Config.Missile.CooldownSeconds

    TriggerClientEvent('resistance:client:playCountdown', -1, Config.Missile.CountdownSeconds)
    Wait(Config.Missile.CountdownSeconds * 1000)

    TriggerClientEvent('resistance:client:missileImpact', -1, payload.mtype, coords)
    TriggerClientEvent('resistance:client:policeMissileBlip', -1, coords, Config.Missile.PoliceBlipDurationSeconds)

    if payload.mtype == 'jamming' then
        TriggerClientEvent('resistance:client:jamPoliceRadio', -1, Config.Missile.JamDurationSeconds)
    end

    broadcast(('تم إطلاق %s.'):format(missileData.label), 'error')
    updateHeat(missileData.heat or 10, ('missile:%s'):format(payload.mtype))
end)

RegisterNetEvent('resistance:server:openWarehouse', function(payload)
    local src = source
    if type(payload) ~= 'table' or not validToken(payload.token) then return end
    local player = getPlayer(src)
    local isRes, rank = hasJobAndRank(player)
    if not isRes then return notify(src, 'ليس لديك وصول للمستودعات.', 'error') end

    local wh = Config.Warehouses[payload.warehouseId]
    if not wh then return end

    if not Resistance.HasMinRank(rank, wh.minRank) then
        return notify(src, 'رتبتك لا تسمح بفتح هذا المستودع.', 'error')
    end

    if Config.Security.EnableWarehouseCode then
        local code = tostring(payload.code or '')
        if #code ~= Config.Security.RequiredWarehouseCodeLength or code ~= tostring(wh.code) then
            return notify(src, 'كود دخول خاطئ.', 'error')
        end
    end

    player.Functions.OpenInventory('stash', wh.stashId, {
        maxweight = wh.weight,
        slots = wh.slots,
    })
    TriggerClientEvent('inventory:client:SetCurrentStash', src, wh.stashId)
end)

RegisterNetEvent('resistance:server:requestGarageVehicles', function(token)
    local src = source
    if not validToken(token) then return end

    local player = getPlayer(src)
    local isRes, rank = hasJobAndRank(player)
    if not isRes then return notify(src, 'الكراج خاص بالمقاومة.', 'error') end

    local allowed = {}
    for k, list in pairs(Config.Garage.Vehicles) do
        if Resistance.HasMinRank(rank, k) then
            for _, veh in ipairs(list) do
                allowed[#allowed + 1] = veh
            end
        end
    end

    TriggerClientEvent('resistance:client:garageMenu', src, allowed)
end)

RegisterNetEvent('resistance:server:spawnGarageVehicle', function(model, token)
    local src = source
    if not validToken(token) or type(model) ~= 'string' then return end

    local player = getPlayer(src)
    local isRes, rank = hasJobAndRank(player)
    if not isRes then return end

    local allowed = false
    for k, list in pairs(Config.Garage.Vehicles) do
        if Resistance.HasMinRank(rank, k) then
            for _, veh in ipairs(list) do
                if veh.model == model then
                    allowed = true
                    break
                end
            end
        end
        if allowed then break end
    end

    if not allowed then
        return notify(src, 'المركبة غير متاحة لرتبتك.', 'error')
    end

    TriggerClientEvent('resistance:client:spawnApprovedVehicle', src, model)
end)

RegisterNetEvent('resistance:server:storeVehicle', function(netId, token)
    local src = source
    if not validToken(token) then return end
    local player = getPlayer(src)
    local isRes = hasJobAndRank(player)
    if not isRes then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 then
        DeleteEntity(entity)
        notify(src, 'تم تخزين المركبة.', 'success')
    end
end)

RegisterNetEvent('resistance:server:openLeaderPanel', function(token)
    local src = source
    if not validToken(token) then return end
    local player = getPlayer(src)
    local allowed = hasJobAndRank(player, Config.LeaderGradeName)
    if not allowed then return end

    TriggerClientEvent('resistance:client:openLeaderPanel', src)
end)

RegisterNetEvent('resistance:server:leaderAnnouncement', function(message, token)
    local src = source
    if not validToken(token) then return end

    local player = getPlayer(src)
    local allowed = hasJobAndRank(player, Config.LeaderGradeName)
    if not allowed then return end

    if type(message) ~= 'string' or #message < 3 or #message > 200 then
        return notify(src, 'نص الإعلان غير صالح.', 'error')
    end

    local now = os.time()
    if now - LastAnnouncement < Config.General.AnnouncementCooldownSeconds then
        return notify(src, 'مهلة بين الإعلانات لم تنته بعد.', 'error')
    end

    LastAnnouncement = now
    broadcast(('بيان القائد: %s'):format(message), 'primary')
end)

RegisterNetEvent('resistance:server:startCinematic', function(payload)
    local src = source
    if type(payload) ~= 'table' or not validToken(payload.token) then return end

    local player = getPlayer(src)
    local allowed = hasJobAndRank(player, Config.LeaderGradeName)
    if not allowed then return end

    local msg = tostring(payload.message or Config.Cinematic.DefaultMessage)
    local image = tostring(payload.image or '')
    local audio = tostring(payload.audio or '')
    local duration = math.floor(tonumber(payload.duration) or Config.Cinematic.DurationSeconds)

    if duration < 5 or duration > 120 then duration = Config.Cinematic.DurationSeconds end
    if #msg < 3 or #msg > 180 then
        return notify(src, 'نص البيان غير صالح.', 'error')
    end

    TriggerClientEvent('resistance:client:cinematic', -1, {
        message = msg,
        image = image ~= '' and image or Config.Cinematic.DefaultImage,
        audio = audio ~= '' and audio or Config.Cinematic.DefaultAudio,
        duration = duration,
    })
end)

RegisterCommand(Config.Joining.LeaderInviteCommand, function(src, args)
    local player = getPlayer(src)
    local allowed = hasJobAndRank(player, Config.LeaderGradeName)
    if not allowed then return notify(src, 'فقط القائد يمكنه ضم أعضاء.', 'error') end

    local targetId = tonumber(args[1] or 0)
    local target = getPlayer(targetId)
    if not target then return notify(src, 'اللاعب غير موجود.', 'error') end

    target.Functions.SetJob(Config.JobName, 0)
    notify(src, ('تم ضم %s للمقاومة.'):format(target.PlayerData.charinfo.firstname), 'success')
    notify(targetId, 'تم تجنيدك في المقاومة كـ مجند.', 'success')
end, false)

RegisterCommand(Config.Joining.LeaderKickCommand, function(src, args)
    local player = getPlayer(src)
    local allowed = hasJobAndRank(player, Config.LeaderGradeName)
    if not allowed then return notify(src, 'فقط القائد يمكنه فصل الأعضاء.', 'error') end

    local targetId = tonumber(args[1] or 0)
    local target = getPlayer(targetId)
    if not target then return notify(src, 'اللاعب غير موجود.', 'error') end

    if target.PlayerData.job.name == Config.JobName then
        target.Functions.SetJob('unemployed', 0)
        notify(targetId, 'تم فصلك من المقاومة.', 'error')
    end
end, false)

CreateThread(function()
    while true do
        Wait(15000)
        for _, src in pairs(QBCore.Functions.GetPlayers()) do
            local ply = getPlayer(src)
            if ply and ply.PlayerData.job and Resistance.IsPolice(ply.PlayerData.job.name) then
                for zoneId, state in pairs(ZoneStates) do
                    if state.owner == 'resistance' then
                        -- Placeholder for dispatch integration
                        TriggerClientEvent('resistance:client:notify', src, ('استخبارات: المقاومة تسيطر على %s'):format(zoneId), 'error')
                    end
                end
            end
        end
    end
end)

RegisterCommand('rescapture', function(src, args)
    local player = getPlayer(src)
    local isRes = hasJobAndRank(player, Config.OperativeGradeName)
    if not isRes then return end

    local zoneId = tostring(args[1] or '')
    local zoneCfg
    for _, z in ipairs(Config.Zones) do
        if z.id == zoneId then zoneCfg = z break end
    end

    if not zoneCfg then return notify(src, 'المنطقة غير موجودة.', 'error') end

    ZoneStates[zoneId].owner = 'resistance'
    updateHeat(12, 'zone_capture')
    player.Functions.AddMoney('cash', zoneCfg.bonusMoney, 'resistance-zone-bonus')
    broadcast(('تم احتلال منطقة %s من قبل المقاومة.'):format(zoneCfg.label), 'success')
end, false)

RegisterCommand('resraid', function(src, args)
    local player = getPlayer(src)
    if not player or not Resistance.IsPolice(player.PlayerData.job.name) then return end

    local whId = tostring(args[1] or '')
    local wh = Config.Warehouses[whId]
    if not wh then return notify(src, 'مستودع غير صحيح.', 'error') end

    broadcast(('الشرطة بدأت مداهمة على %s!'):format(wh.label), 'error')
    updateHeat(8, 'police_raid')
end, false)

RegisterCommand('reswanted', function(src, args)
    local player = getPlayer(src)
    local allowed = hasJobAndRank(player, Config.CommanderGradeName)
    if not allowed then return end

    local citizenId = tostring(args[1] or '')
    local reason = table.concat(args, ' ', 2)
    if citizenId == '' or reason == '' then
        return notify(src, 'الاستخدام: /reswanted [citizenid] [reason]', 'error')
    end

    TrackedWanted[citizenId] = {
        reason = reason,
        by = src,
        at = os.time(),
    }

    notify(src, ('تمت إضافة %s لقائمة التتبع.'):format(citizenId), 'success')
end, false)

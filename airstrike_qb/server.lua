local QBCore = exports['qb-core']:GetCoreObject()

local Cooldowns = {}
local Pending = {}

local function now()
    return os.time()
end

local function isInSafeZone(coords)
    for _, zone in ipairs(Config.SafeZones) do
        if #(coords - zone.coords) <= zone.radius then
            return true
        end
    end
    return false
end

local function hasPermission(Player)
    if not Config.RequireJob then return true end
    local job = Player.PlayerData.job
    if not job then return false end
    local minGrade = Config.AllowedJobs[job.name]
    if minGrade == nil then return false end
    return (job.grade.level or 0) >= minGrade
end

local function chargePlayer(Player, strikeType)
    if not Config.UseMoney then return true end
    local price = Config.Cost[strikeType] or Config.Cost.single
    if Player.Functions.RemoveMoney(Config.MoneyType, price, 'airstrike-call') then
        return true
    end
    return false
end

QBCore.Functions.CreateCallback('airstrike:server:canCall', function(source, cb, payload)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, 'Player not found') end

    if not payload or not payload.strikeType or not payload.coords then
        return cb(false, 'Invalid payload')
    end

    local strikeType = payload.strikeType
    if not Config.StrikeTypes[strikeType] then
        return cb(false, 'Unknown strike type')
    end

    local coords = vector3(payload.coords.x, payload.coords.y, payload.coords.z)
    if isInSafeZone(coords) then
        return cb(false, 'Target inside safe zone')
    end

    if not hasPermission(Player) then
        return cb(false, 'Unauthorized rank/job')
    end

    local cdEnd = Cooldowns[source] or 0
    local remaining = cdEnd - now()
    if remaining > 0 then
        return cb(false, ('Cooldown: %ss'):format(remaining))
    end

    if not chargePlayer(Player, strikeType) then
        return cb(false, 'Not enough money')
    end

    cb(true)
end)

RegisterNetEvent('airstrike:server:requestStrike', function(payload)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not payload or not payload.coords then return end

    local strikeType = payload.strikeType or 'single'
    local cfg = Config.StrikeTypes[strikeType]
    if not cfg then return end

    local coords = vector3(payload.coords.x, payload.coords.y, payload.coords.z)
    if isInSafeZone(coords) then
        TriggerClientEvent('QBCore:Notify', src, 'Target inside safe zone', 'error')
        return
    end

    local token = ('%s_%s_%s'):format(src, strikeType, GetGameTimer())
    Pending[src] = token

    TriggerClientEvent('airstrike:client:pendingStrike', src, {
        token = token,
        countdown = Config.CountdownSeconds,
        cancelWindow = Config.CancelWindowSeconds,
    })

    TriggerClientEvent('airstrike:client:globalWarning', -1, {
        text = Config.Warning.globalText,
        coords = coords,
        pingDuration = Config.RadarPingDurationMs,
    })

    SetTimeout(Config.CancelWindowSeconds * 1000, function()
        if Pending[src] ~= token then return end

        Pending[src] = nil
        Cooldowns[src] = now() + Config.CooldownSeconds

        local antiIntercepted = false
        if Config.AntiMissile.enabled then
            antiIntercepted = math.random(1, 100) <= Config.AntiMissile.chance
        end

        local netPayload = {
            caller = src,
            strikeType = strikeType,
            coords = coords,
            config = cfg,
            antiIntercepted = antiIntercepted,
            randomOffset = Config.RandomOffsetRadius,
            missile = Config.Missile,
            explosion = Config.Explosion,
            fireZoneDuration = Config.FireZoneDurationMs,
            fireZoneTick = Config.FireZoneTickMs,
            fireZoneRadius = Config.FireZoneRadius,
            jamDuration = Config.JamDurationMs,
        }

        TriggerClientEvent('airstrike:client:startStrike', -1, netPayload)
        TriggerClientEvent('QBCore:Notify', src, Config.Warning.callerConfirm, 'success')
    end)
end)

RegisterNetEvent('airstrike:server:cancelStrike', function(token)
    local src = source
    if token and Pending[src] == token then
        Pending[src] = nil
        TriggerClientEvent('QBCore:Notify', src, Config.Warning.cancelText, 'primary')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Pending[src] = nil
    Cooldowns[src] = nil
end)

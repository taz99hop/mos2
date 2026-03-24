local MAX_RANGE = 7000.0
local COUNTDOWN_MS = 5000
local COOLDOWN_SEC = 90
local MIN_FLIGHT_MS = 3800
local MAX_FLIGHT_MS = 8500

local lastStrikeAt = {}

local function v3(t)
    return vector3(tonumber(t.x) or 0.0, tonumber(t.y) or 0.0, tonumber(t.z) or 0.0)
end

local function getCooldownLeft(src)
    local now = os.time()
    local prev = lastStrikeAt[src] or 0
    local diff = now - prev
    if diff >= COOLDOWN_SEC then
        return 0
    end
    return COOLDOWN_SEC - diff
end

AddEventHandler("playerDropped", function()
    lastStrikeAt[source] = nil
end)

RegisterNetEvent("himars:requestStrike", function(payload)
    local src = source

    if not IsPlayerAceAllowed(src, "mlrs.use") then
        TriggerClientEvent("himars:notify", src, "~r~No permission (mlrs.use)")
        return
    end

    local left = getCooldownLeft(src)
    if left > 0 then
        TriggerClientEvent("himars:notify", src, ("~r~Reloading... wait %ss"):format(left))
        return
    end

    if type(payload) ~= "table" then
        return
    end

    local target = v3(payload.target or {})
    local launch = v3(payload.launch or {})
    local dist = #(target - launch)

    if dist > MAX_RANGE then
        TriggerClientEvent("himars:notify", src, "~r~Target out of range")
        return
    end

    local rockets = math.floor(tonumber(payload.rockets) or 6)
    local spread = tonumber(payload.spread) or 35.0
    local delayMs = math.floor(tonumber(payload.delayMs) or 500)

    rockets = math.max(1, math.min(rockets, 24))
    spread = math.max(1.0, math.min(spread, 120.0))
    delayMs = math.max(150, math.min(delayMs, 2000))

    lastStrikeAt[src] = os.time()

    TriggerClientEvent("himars:startCountdown", -1, { x = target.x, y = target.y, z = target.z }, COUNTDOWN_MS)

    CreateThread(function()
        Wait(COUNTDOWN_MS)

        for _ = 1, rockets do
            local ox = (math.random() * 2.0 - 1.0) * spread
            local oy = (math.random() * 2.0 - 1.0) * spread
            local strikeTarget = vector3(target.x + ox, target.y + oy, target.z)

            local distance = #(strikeTarget - launch)
            local norm = math.min(1.0, math.max(0.0, distance / MAX_RANGE))
            local flightMs = math.floor(MIN_FLIGHT_MS + (MAX_FLIGHT_MS - MIN_FLIGHT_MS) * norm)

            TriggerClientEvent("himars:spawnMissile", -1, {
                launch = { x = launch.x, y = launch.y, z = launch.z },
                target = { x = strikeTarget.x, y = strikeTarget.y, z = strikeTarget.z },
                flightMs = flightMs
            })

            Wait(delayMs)
        end
    end)
end)

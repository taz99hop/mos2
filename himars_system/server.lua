local MAX_RANGE = 7000.0

local function v3(t)
    return vector3(tonumber(t.x) or 0.0, tonumber(t.y) or 0.0, tonumber(t.z) or 0.0)
end

RegisterNetEvent("himars:requestStrike", function(payload)
    local src = source

    if not IsPlayerAceAllowed(src, "mlrs.use") then
        print(("MLRS denied for %s (no ace)"):format(src))
        return
    end

    if type(payload) ~= "table" then
        return
    end

    local target = v3(payload.target or {})
    local launch = v3(payload.launch or {})

    local dist = #(target - launch)
    if dist > MAX_RANGE then
        print(("MLRS denied for %s (range %.1f)"):format(src, dist))
        return
    end

    local rockets = math.floor(tonumber(payload.rockets) or 6)
    local spread = tonumber(payload.spread) or 35.0
    local delayMs = math.floor(tonumber(payload.delayMs) or 500)
    local netVeh = tonumber(payload.netVeh) or 0

    rockets = math.max(1, math.min(rockets, 24))
    spread = math.max(1.0, math.min(spread, 120.0))
    delayMs = math.max(150, math.min(delayMs, 2000))

    CreateThread(function()
        for _ = 1, rockets do
            TriggerClientEvent("himars:launchFx", -1, netVeh)

            local ox = (math.random() * 2.0 - 1.0) * spread
            local oy = (math.random() * 2.0 - 1.0) * spread

            TriggerClientEvent("himars:impactFx", -1, target.x + ox, target.y + oy, target.z)

            Wait(delayMs)
        end
    end)
end)

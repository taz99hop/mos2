local QBCore = exports['qb-core']:GetCoreObject()

local state = {
    isOpen = false,
    isRisen = false,
    isArmed = false,
    isBusy = false,
    missileType = 'tactical',
    target = { x = 0.0, y = 0.0, z = 0.0 },
    launchReady = false,
    sequence = 'idle'
}

local function syncState()
    if Config.UseStateBags then
        GlobalState.undergroundSilo = state
    end
    TriggerClientEvent('underground_silo:client:updateState', -1, state)
end

local function hasPermission(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end
    local job = player.PlayerData.job and player.PlayerData.job.name
    return job and Config.AuthorizedJobs[job] == true
end

local function setBusy(flag, sequence)
    state.isBusy = flag
    state.sequence = sequence or state.sequence
    syncState()
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    TriggerClientEvent('underground_silo:client:updateState', src, state)
end)

RegisterNetEvent('underground_silo:server:setTarget', function(data)
    local src = source
    if not hasPermission(src) then return end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)

    if not x or not y or not z then return end

    state.target = { x = x, y = y, z = z }
    state.launchReady = state.isOpen and state.isRisen and state.isArmed
    syncState()
end)

RegisterNetEvent('underground_silo:server:setMissileType', function(missileType)
    local src = source
    if not hasPermission(src) then return end
    if not Config.Missiles[missileType] then return end

    state.missileType = missileType
    syncState()
end)

RegisterNetEvent('underground_silo:server:step', function(action)
    local src = source
    if not hasPermission(src) then return end
    if state.isBusy then return end

    if action == 'open_hatch' then
        if state.isOpen then return end
        setBusy(true, 'opening_hatch')
        TriggerClientEvent('underground_silo:client:doStep', -1, 'open_hatch')
        Wait(Config.Sequence.hatchOpenMs)
        state.isOpen = true
        state.isBusy = false
        state.sequence = 'hatch_opened'

    elseif action == 'raise_platform' then
        if not state.isOpen or state.isRisen then return end
        setBusy(true, 'raising_platform')
        TriggerClientEvent('underground_silo:client:doStep', -1, 'raise_platform')
        Wait(Config.Sequence.platformRiseMs)
        state.isRisen = true
        state.isBusy = false
        state.sequence = 'platform_up'

    elseif action == 'arm_target' then
        if not state.isRisen or state.isArmed then return end
        setBusy(true, 'arming_vertical')
        TriggerClientEvent('underground_silo:client:doStep', -1, 'arm_vertical')
        Wait(Config.Sequence.armPitchMs)
        state.isArmed = true
        state.launchReady = true
        state.isBusy = false
        state.sequence = 'armed'

    elseif action == 'launch' then
        if not state.launchReady then return end
        state.launchReady = false
        setBusy(true, 'launching')

        local payload = {
            type = state.missileType,
            target = state.target
        }
        TriggerClientEvent('underground_silo:client:doStep', -1, 'launch', payload)

        Wait(3500)
        TriggerClientEvent('underground_silo:client:doStep', -1, 'cleanup')
        state.isOpen = false
        state.isRisen = false
        state.isArmed = false
        state.isBusy = false
        state.sequence = 'cooldown'
        SetTimeout(Config.CleanupAfterMs, function()
            state.sequence = 'idle'
            syncState()
        end)
    else
        return
    end

    syncState()
end)

CreateThread(function()
    syncState()
end)

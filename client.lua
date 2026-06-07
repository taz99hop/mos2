local spawnedPlanes = {}
local convoyActive = false

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        Wait(0)
        if GetGameTimer() > timeout then
            return false
        end
    end
    return true
end

local function randomSpawnPoint(index)
    local angle = (index / Config.PlaneCount) * math.pi * 2.0
    local radius = math.random() * Config.SpawnRadius
    local x = Config.SpawnCenter.x + math.cos(angle) * radius
    local y = Config.SpawnCenter.y + math.sin(angle) * radius
    local z = Config.CruiseAltitude + math.random(50, 220)
    return vector3(x, y, z)
end

local function assignTarget(index)
    local target = Config.Targets[((index - 1) % #Config.Targets) + 1]
    local finalAltitude = target.z
    local cruiseTarget = vector3(target.x, target.y, Config.CruiseAltitude)
    return cruiseTarget, finalAltitude
end

local function createPlaneBlip(plane, index)
    local blip = AddBlipForEntity(plane)
    SetBlipSprite(blip, 307)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.75)
    SetBlipAsShortRange(blip, false)
    ShowHeadingIndicatorOnBlip(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('Plane %02d'):format(index))
    EndTextCommandSetBlipName(blip)

    return blip
end

local function createPlaneWithPilot(index)
    local spawn = randomSpawnPoint(index)
    local cruiseTarget, finalAltitude = assignTarget(index)

    local heading = GetHeadingFromVector_2d(cruiseTarget.x - spawn.x, cruiseTarget.y - spawn.y)

    local plane = CreateVehicle(Config.PlaneModel, spawn.x, spawn.y, spawn.z, heading, true, false)
    if not DoesEntityExist(plane) then return end

    SetVehicleEngineOn(plane, true, true, false)
    SetEntityAsMissionEntity(plane, true, true)
    SetVehicleForwardSpeed(plane, 90.0)

    local pilot = CreatePedInsideVehicle(plane, 26, Config.PilotModel, -1, true, false)
    if not DoesEntityExist(pilot) then
        DeleteEntity(plane)
        return
    end

    SetEntityAsMissionEntity(pilot, true, true)
    SetBlockingOfNonTemporaryEvents(pilot, true)

    TaskPlaneMission(
        pilot,
        plane,
        0,
        0,
        cruiseTarget.x,
        cruiseTarget.y,
        cruiseTarget.z,
        4,
        120.0,
        0.0,
        heading,
        250.0,
        80.0
    )

    local blip = createPlaneBlip(plane, index)

    spawnedPlanes[#spawnedPlanes + 1] = {
        plane = plane,
        pilot = pilot,
        blip = blip,
        target = vector3(cruiseTarget.x, cruiseTarget.y, finalAltitude),
        descending = false
    }
end

local function clearConvoy()
    for _, data in pairs(spawnedPlanes) do
        if data.blip and DoesBlipExist(data.blip) then
            RemoveBlip(data.blip)
        end
        if DoesEntityExist(data.pilot) then DeleteEntity(data.pilot) end
        if DoesEntityExist(data.plane) then DeleteEntity(data.plane) end
    end
    spawnedPlanes = {}
    convoyActive = false
end

local function startPlanesConvoy()
    if convoyActive then
        TriggerEvent('chat:addMessage', { args = { '^3[Planes]', 'Convoy already spawned.' } })
        return
    end

    if not loadModel(Config.PlaneModel) then
        print('[qb-planes-convoy] Failed loading plane model')
        return
    end

    if not loadModel(Config.PilotModel) then
        print('[qb-planes-convoy] Failed loading pilot model')
        return
    end

    convoyActive = true

    for i = 1, Config.PlaneCount do
        createPlaneWithPilot(i)
        Wait(250)
    end

    SetModelAsNoLongerNeeded(Config.PlaneModel)
    SetModelAsNoLongerNeeded(Config.PilotModel)

    TriggerEvent('chat:addMessage', { args = { '^2[Planes]', ('Spawned %d planes.'):format(Config.PlaneCount) } })
end

RegisterCommand('spawnplanes', function()
    startPlanesConvoy()
end, false)

RegisterCommand('clearplanes', function()
    clearConvoy()
    TriggerEvent('chat:addMessage', { args = { '^1[Planes]', 'All spawned planes cleared.' } })
end, false)

CreateThread(function()
    while true do
        Wait(1000)
        for i = #spawnedPlanes, 1, -1 do
            local data = spawnedPlanes[i]
            if DoesEntityExist(data.plane) and DoesEntityExist(data.pilot) then
                local planeCoords = GetEntityCoords(data.plane)
                local dist2D = #(vector2(planeCoords.x, planeCoords.y) - vector2(data.target.x, data.target.y))

                if not data.descending and dist2D < 3500.0 then
                    data.descending = true
                    TaskPlaneMission(
                        data.pilot,
                        data.plane,
                        0,
                        0,
                        data.target.x,
                        data.target.y,
                        data.target.z,
                        4,
                        95.0,
                        0.0,
                        GetEntityHeading(data.plane),
                        120.0,
                        60.0
                    )
                end
            else
                if data and data.blip and DoesBlipExist(data.blip) then
                    RemoveBlip(data.blip)
                end
                table.remove(spawnedPlanes, i)
            end
        end

        if convoyActive and #spawnedPlanes == 0 then
            convoyActive = false
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    clearConvoy()
end)

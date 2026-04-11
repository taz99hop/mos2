local QBCore = exports['qb-core']:GetCoreObject()

local function IsResistanceAndRankAllowed(allowed)
    local pd = QBCore.Functions.GetPlayerData()
    local rank = Resistance.GetGradeName(pd)
    return rank and Resistance.HasAccessByMap(rank, allowed)
end

local function AddManufacturingTargets()
    for stationId, station in pairs(Config.ManufacturingStations) do
        exports['qb-target']:AddBoxZone(('resistance_mf_%s'):format(stationId), station.coords, 1.4, 1.0, {
            name = ('resistance_mf_%s'):format(stationId),
            heading = station.heading,
            debugPoly = Config.Debug,
            minZ = station.coords.z - 1.0,
            maxZ = station.coords.z + 1.5,
        }, {
            options = {
                {
                    icon = station.icon,
                    label = ('فتح %s'):format(station.label),
                    canInteract = function()
                        return IsResistanceAndRankAllowed(station.allowedRanks)
                    end,
                    action = function()
                        TriggerEvent('resistance:client:openManufacturingMenu', stationId)
                    end
                }
            },
            distance = Config.General.DefaultInteractionDistance
        })
    end
end

local function AddMissileConsoleTarget()
    local coords = Config.Missile.LaunchConsole
    exports['qb-target']:AddBoxZone('resistance_launch_console', coords, 1.2, 1.2, {
        name = 'resistance_launch_console',
        heading = 0.0,
        debugPoly = Config.Debug,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 1.2,
    }, {
        options = {
            {
                icon = 'fas fa-rocket',
                label = 'لوحة إطلاق الصواريخ',
                canInteract = function()
                    local pd = QBCore.Functions.GetPlayerData()
                    local rank = Resistance.GetGradeName(pd)
                    return rank == Config.LeaderGradeName
                end,
                action = function()
                    TriggerEvent('resistance:client:openMissilePanel')
                end,
            }
        },
        distance = Config.General.DefaultInteractionDistance
    })
end

local function AddWarehouseTargets()
    for warehouseId, wh in pairs(Config.Warehouses) do
        exports['qb-target']:AddBoxZone(('resistance_wh_%s'):format(warehouseId), wh.coords, 1.2, 1.0, {
            name = ('resistance_wh_%s'):format(warehouseId),
            heading = 0.0,
            debugPoly = Config.Debug,
            minZ = wh.coords.z - 1.0,
            maxZ = wh.coords.z + 1.2,
        }, {
            options = {
                {
                    icon = 'fas fa-warehouse',
                    label = ('فتح %s'):format(wh.label),
                    action = function()
                        TriggerEvent('resistance:client:openWarehouse', warehouseId)
                    end
                }
            },
            distance = Config.General.DefaultInteractionDistance
        })
    end
end

local function AddGarageTargets()
    local ped = Config.Garage.PedSpawn
    exports['qb-target']:AddBoxZone('resistance_garage_spawn', vec3(ped.x, ped.y, ped.z), 1.4, 1.0, {
        name = 'resistance_garage_spawn',
        heading = ped.w,
        debugPoly = Config.Debug,
        minZ = ped.z - 1.0,
        maxZ = ped.z + 1.6,
    }, {
        options = {
            {
                icon = 'fas fa-car-side',
                label = 'كراج المقاومة',
                action = function()
                    TriggerEvent('resistance:client:openGarage')
                end
            }
        },
        distance = Config.General.DefaultInteractionDistance
    })

    exports['qb-target']:AddBoxZone('resistance_garage_store', Config.Garage.StorePoint, 2.5, 2.5, {
        name = 'resistance_garage_store',
        heading = 0.0,
        debugPoly = Config.Debug,
        minZ = Config.Garage.StorePoint.z - 1.0,
        maxZ = Config.Garage.StorePoint.z + 2.0,
    }, {
        options = {
            {
                icon = 'fas fa-square-parking',
                label = 'تخزين المركبة',
                action = function()
                    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                    if veh ~= 0 then
                        TriggerServerEvent('resistance:server:storeVehicle', NetworkGetNetworkIdFromEntity(veh), Config.Security.ServerEventToken)
                    end
                end
            }
        },
        distance = 3.0
    })
end

CreateThread(function()
    Wait(1200)
    AddManufacturingTargets()
    AddMissileConsoleTarget()
    AddWarehouseTargets()
    AddGarageTargets()
end)

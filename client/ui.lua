local QBCore = exports['qb-core']:GetCoreObject()

local function playAnim(dict, clip, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(20) end
    TaskPlayAnim(PlayerPedId(), dict, clip, 3.0, 3.0, duration, 1, 0.0, false, false, false)
end

local function runProgress(label, duration)
    QBCore.Functions.Progressbar('resistance_action', label, duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        ClearPedTasks(PlayerPedId())
    end, function()
        ClearPedTasks(PlayerPedId())
    end)
end

RegisterNetEvent('resistance:client:openManufacturingMenu', function(stationId)
    local station = Config.ManufacturingStations[stationId]
    if not station then return end

    local menu = {
        {
            header = station.label,
            isMenuHeader = true,
        }
    }

    for _, recipe in ipairs(station.recipes) do
        local reqText = {}
        for item, amount in pairs(recipe.requirements) do
            reqText[#reqText + 1] = ('%s x%s'):format(item, amount)
        end

        menu[#menu + 1] = {
            header = recipe.label,
            txt = ('الوقت: %s ث | المتطلبات: %s'):format(math.floor(recipe.duration / 1000), table.concat(reqText, ', ')),
            params = {
                event = 'resistance:client:craftRecipe',
                args = { stationId = stationId, recipeId = recipe.id }
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('resistance:client:craftRecipe', function(data)
    local station = Config.ManufacturingStations[data.stationId]
    if not station then return end

    local recipe
    for _, r in ipairs(station.recipes) do
        if r.id == data.recipeId then
            recipe = r
            break
        end
    end

    if not recipe then return end

    playAnim(station.animation.dict, station.animation.clip, recipe.duration)
    runProgress(('جاري تصنيع %s'):format(recipe.label), recipe.duration)
    Wait(recipe.duration)

    TriggerServerEvent('resistance:server:craftRecipe', {
        stationId = data.stationId,
        recipeId = data.recipeId,
        token = Config.Security.ServerEventToken,
    })
end)

RegisterNetEvent('resistance:client:openMissilePanel', function()
    local input = exports['qb-input']:ShowInput({
        header = 'لوحة إطلاق الصواريخ',
        submitText = 'إطلاق',
        inputs = {
            {
                text = 'النوع (explosive/jamming/smoke)',
                name = 'mtype',
                type = 'text',
                isRequired = true,
            },
            {
                text = 'X',
                name = 'x',
                type = 'number',
                isRequired = true,
            },
            {
                text = 'Y',
                name = 'y',
                type = 'number',
                isRequired = true,
            },
            {
                text = 'Z',
                name = 'z',
                type = 'number',
                isRequired = true,
            }
        }
    })

    if not input then return end
    local missileType = tostring(input.mtype or ''):lower()
    TriggerServerEvent('resistance:server:launchMissile', {
        mtype = missileType,
        coords = vec3(tonumber(input.x) or 0.0, tonumber(input.y) or 0.0, tonumber(input.z) or 0.0),
        token = Config.Security.ServerEventToken,
    })
end)

RegisterNetEvent('resistance:client:openWarehouse', function(warehouseId)
    local input = exports['qb-input']:ShowInput({
        header = 'رمز الدخول للمستودع',
        submitText = 'تأكيد',
        inputs = {
            {
                text = 'ادخل الكود',
                name = 'code',
                type = 'password',
                isRequired = true,
            }
        }
    })

    if not input then return end
    TriggerServerEvent('resistance:server:openWarehouse', {
        warehouseId = warehouseId,
        code = tostring(input.code),
        token = Config.Security.ServerEventToken,
    })
end)

RegisterNetEvent('resistance:client:openLeaderPanel', function()
    local menu = {
        { header = 'لوحة القائد', isMenuHeader = true },
        {
            header = 'إعلان عام',
            txt = 'إرسال إعلان لجميع اللاعبين',
            params = { event = 'resistance:client:leaderAnnouncement' }
        },
        {
            header = 'بدء بيان القائد (سينمائي)',
            txt = 'شاشة سوداء + صورة + نص + صوت',
            params = { event = 'resistance:client:leaderCinematicPrompt' }
        },
        {
            header = 'إطلاق صاروخ',
            txt = 'فتح لوحة الصواريخ',
            params = { event = 'resistance:client:openMissilePanel' }
        }
    }

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('resistance:client:leaderAnnouncement', function()
    local input = exports['qb-input']:ShowInput({
        header = 'إعلان القائد',
        submitText = 'إرسال',
        inputs = {
            { text = 'نص الإعلان', name = 'message', type = 'text', isRequired = true }
        }
    })

    if not input then return end
    TriggerServerEvent('resistance:server:leaderAnnouncement', tostring(input.message), Config.Security.ServerEventToken)
end)

RegisterNetEvent('resistance:client:leaderCinematicPrompt', function()
    local input = exports['qb-input']:ShowInput({
        header = 'بيان القائد',
        submitText = 'بث',
        inputs = {
            { text = 'النص', name = 'message', type = 'text', isRequired = true },
            { text = 'رابط صورة', name = 'image', type = 'text', isRequired = false },
            { text = 'رابط صوت', name = 'audio', type = 'text', isRequired = false },
            { text = 'مدة بالثواني', name = 'duration', type = 'number', isRequired = true },
        }
    })

    if not input then return end
    TriggerServerEvent('resistance:server:startCinematic', {
        message = tostring(input.message),
        image = tostring(input.image or ''),
        audio = tostring(input.audio or ''),
        duration = tonumber(input.duration) or Config.Cinematic.DurationSeconds,
        token = Config.Security.ServerEventToken,
    })
end)

RegisterNetEvent('resistance:client:openGarage', function()
    TriggerServerEvent('resistance:server:requestGarageVehicles', Config.Security.ServerEventToken)
end)

RegisterNetEvent('resistance:client:garageMenu', function(vehicles)
    local menu = {
        { header = 'كراج المقاومة', isMenuHeader = true }
    }

    for _, veh in ipairs(vehicles) do
        menu[#menu + 1] = {
            header = veh.label,
            txt = veh.model,
            params = {
                event = 'resistance:client:spawnGarageVehicle',
                args = veh,
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('resistance:client:spawnGarageVehicle', function(data)
    TriggerServerEvent('resistance:server:spawnGarageVehicle', data.model, Config.Security.ServerEventToken)
end)

RegisterNetEvent('resistance:client:spawnApprovedVehicle', function(model)
    local spawn = Config.Garage.SpawnPoint
    QBCore.Functions.SpawnVehicle(model, function(vehicle)
        SetVehicleNumberPlateText(vehicle, ('RES%03d'):format(math.random(100, 999)))
        SetEntityHeading(vehicle, spawn.w)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        SetVehicleEngineOn(vehicle, true, true)
    end, vec3(spawn.x, spawn.y, spawn.z), true)
end)

RegisterCommand('resleader', function()
    TriggerServerEvent('resistance:server:openLeaderPanel', Config.Security.ServerEventToken)
end, false)

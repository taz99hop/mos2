local QBCore = exports['qb-core']:GetCoreObject()

local ItemDef = {
    name = 'panic_device',
    label = 'جهاز نداء طوارئ',
    weight = 1,
    type = 'item',
    image = 'panic_device.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'جهاز إرسال نداء طوارئ للعساكر'
}

local Snippet = [[
['panic_device'] = {
    ['name'] = 'panic_device',
    ['label'] = 'جهاز نداء طوارئ',
    ['weight'] = 1,
    ['type'] = 'item',
    ['image'] = 'panic_device.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'جهاز إرسال نداء طوارئ للعساكر'
},
]]

local function EnsureRuntimeItem()
    if not QBCore.Shared.Items[ItemDef.name] then
        QBCore.Shared.Items[ItemDef.name] = ItemDef
        print('[qb-panicdevice] Added panic_device to QBCore.Shared.Items at runtime.')
    end
end

local function EnsureCoreFileItem()
    local corePath = GetResourcePath('qb-core')
    if not corePath then
        print('[qb-panicdevice] Could not resolve qb-core resource path.')
        return
    end

    local itemsPath = corePath .. '/shared/items.lua'
    local file = io.open(itemsPath, 'r')
    if not file then
        print('[qb-panicdevice] Could not open qb-core shared/items.lua for install step.')
        return
    end

    local content = file:read('*a')
    file:close()

    if content:find("%['panic_device'%]") then
        return
    end

    local insertPos = content:match('^.*()}%s*$')
    if not insertPos then
        local fallback = content:gsub('%s*}$', ',\n' .. Snippet .. '\n}')
        if fallback == content then
            print('[qb-panicdevice] Failed to append panic_device into items.lua. Please add manually.')
            return
        end
        content = fallback
    else
        content = content:gsub('}%s*$', Snippet .. '\n}')
    end

    local writeFile = io.open(itemsPath, 'w+')
    if not writeFile then
        print('[qb-panicdevice] Could not write qb-core shared/items.lua for install step.')
        return
    end

    writeFile:write(content)
    writeFile:close()
    print('[qb-panicdevice] panic_device item inserted into qb-core/shared/items.lua.')
end

CreateThread(function()
    Wait(1500)
    EnsureRuntimeItem()
    EnsureCoreFileItem()
end)

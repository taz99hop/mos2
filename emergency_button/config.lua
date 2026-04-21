Config = {}

-- General
Config.Debug = false
Config.CooldownSeconds = 180 -- 2-5 minutes recommended
Config.AlertMessage = '🚨 محاولة هروب في الزنزانات!'

-- Permissions
Config.PoliceJobName = 'police'
Config.AllowPrisoners = false -- if true, non-police can trigger too

-- Emergency button props/locations
-- You can use one or both methods:
-- 1) Add target directly on prop models (for existing map props)
Config.TargetModels = {
    `hei_prop_heist_alarm`,
}

-- 2) Add target zones to specific coordinates
Config.TargetZones = {
    {
        name = 'mrpd_cell_alarm_button',
        coords = vector3(1842.28, 2585.83, 45.01),
        length = 0.6,
        width = 0.6,
        heading = 0.0,
        minZ = 44.5,
        maxZ = 45.5,
    }
}

-- Alarm behavior
Config.Alarm = {
    DurationSeconds = 20,
    SoundIntervalMs = 1500,
    NativeSound = {
        name = '5_SEC_WARNING',
        set = 'HUD_MINI_GAME_SOUNDSET',
    },
    UseInteractSound = false,
    InteractSoundFile = 'alarm',
    InteractSoundVolume = 0.8,
}

-- Police station doors to lock via qb-doorlock
Config.DoorsToLock = {
    -- Examples: 1, 2, 3
}

-- Blip settings
Config.Blip = {
    Sprite = 161,
    Color = 1,
    Scale = 1.2,
    Label = 'بلاغ طوارئ - الزنزانات',
    TimeoutSeconds = 60,
}

Config = {}

Config.Debug = false
Config.VehicleModel = `patriotaa`

-- ثلاث نقاط انتشار ثابتة داخل Los Santos
Config.SpawnPoints = {
    {
        coords = vector4(220.14, -806.55, 30.72, 157.0), -- قرب Legion Square
        protectedCenter = vector3(220.14, -806.55, 30.72),
    },
    {
        coords = vector4(-551.12, -191.41, 38.22, 29.0), -- Burton
        protectedCenter = vector3(-551.12, -191.41, 38.22),
    },
    {
        coords = vector4(1854.61, 3683.75, 34.27, 210.0), -- East LS edge / El Burro
        protectedCenter = vector3(1854.61, 3683.75, 34.27),
    }
}

Config.NpcModel = `s_m_y_blackops_01`
Config.NpcSeat = -1
Config.NpcAnim = {
    dict = "amb@world_human_binoculars@male@enter",
    name = "enter"
}

Config.RadarEnabledByDefault = true
Config.RadarRange = 900.0
Config.ScanIntervalMs = 500
Config.MinThreatSpeed = 40.0 -- m/s
Config.MinHitChance = 0.60
Config.CooldownMs = 3000
Config.MaxTrackedTargets = 3
Config.MaxMissilesPerVehicle = 24
Config.InterceptorSpeed = 155.0 -- m/s
Config.InterceptorLifeMs = 15000
Config.InterceptDistance = 8.0
Config.TurnRateDegPerTick = 5.0
Config.LaunchOffset = vector3(0.0, 3.5, 2.2)
Config.TargetLostTimeoutMs = 1500

Config.IgnorePedThreat = true
Config.IgnoreCars = true

Config.Effects = {
    launchSound = "5_SEC_WARNING",
    launchSoundSet = "HUD_MINI_GAME_SOUNDSET",
    sirenSound = "TIMER_STOP",
    sirenSoundSet = "HUD_MINI_GAME_SOUNDSET",
    launchPtfx = {
        dict = "core",
        name = "exp_grd_flare",
        scale = 1.2,
    },
    smokePtfx = {
        dict = "core",
        name = "ent_sht_steam",
        scale = 0.4,
    },
    interceptExplosion = {
        type = 29,
        damageScale = 1.0,
        audible = true,
        invisible = false
    }
}

Config.Commands = {
    toggle = "patriotradar",
    spawn = "patriotspawn"
}

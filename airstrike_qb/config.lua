Config = {}

Config.UseCommand = true
Config.CommandName = 'strike'
Config.CancelCommandName = 'strikecancel'
Config.OpenUiEvent = 'airstrike:client:openMenu' -- optional hook for custom UI

Config.CountdownSeconds = 7
Config.CancelWindowSeconds = 5
Config.TargetMaxDistance = 1000.0
Config.RandomOffsetRadius = 4.0
Config.AlertRadius = 300.0
Config.JamDurationMs = 7000
Config.RadarPingDurationMs = 10000
Config.FireZoneDurationMs = 12000
Config.FireZoneTickMs = 1000
Config.FireZoneRadius = 8.0

Config.RequireJob = false
Config.AllowedJobs = {
    ['police'] = 2,
    ['army'] = 0,
}

Config.UseMoney = true
Config.MoneyType = 'bank'
Config.Cost = {
    single = 2500,
    cluster = 6000,
    carpet = 10000,
}

Config.CooldownSeconds = 180

Config.StrikeTypes = {
    single = {
        label = 'Single Strike',
        missiles = 1,
        delayBetween = 250,
        spreadRadius = 0.0,
        linePattern = false,
    },
    cluster = {
        label = 'Cluster Strike',
        missiles = 6,
        delayBetween = 350,
        spreadRadius = 20.0,
        linePattern = false,
    },
    carpet = {
        label = 'Carpet Bombing',
        missiles = 10,
        delayBetween = 200,
        spreadRadius = 45.0,
        linePattern = true,
    }
}

Config.SafeZones = {
    { coords = vector3(215.76, -810.12, 30.73), radius = 140.0 }, -- legion style example
    { coords = vector3(-267.0, -960.0, 31.2), radius = 90.0 }
}

Config.Warning = {
    globalText = '⚠️ Incoming Missile Strike',
    callerConfirm = 'Strike confirmed, incoming...',
    cancelText = 'Strike aborted.',
}

Config.Explosion = {
    explosionType = 29,
    damageScale = 6.0,
    audibleDistance = 300.0,
    cameraShake = 1.2,
    vehiclePushForce = 40.0,
}

Config.Marker = {
    type = 1,
    color = { r = 255, g = 40, b = 40, a = 170 },
    scale = vec3(2.8, 2.8, 1.2),
}

Config.Missile = {
    model = `w_lr_rpg_rocket`,
    startHeight = 850.0,
    minSpeed = 45.0,
    maxSpeed = 280.0,
    acceleration = 1.65,
}

Config.Laser = {
    enabled = true,
    key = 47, -- G
    maxDistance = 700.0,
    requireWeapon = false,
}

Config.Drone = {
    enabled = true,
    durationSeconds = 25,
}

Config.AntiMissile = {
    enabled = true,
    chance = 15, -- percent
}

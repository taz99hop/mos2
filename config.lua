Config = {}

Config.Debug = false

Config.LaunchPads = {
    {
        id = 1,
        coords = vector4(845.17, -2102.43, 30.52, 177.1)
    },
    {
        id = 2,
        coords = vector4(904.66, -2114.91, 30.49, 176.8)
    }
}

Config.Models = {
    pad = 'cube',
    missile = 'cylinder'
}

Config.Missile = {
    spawnOffset = vec3(0.0, 0.0, 1.4),
    ascentDuration = 5.0,
    ascentSpeed = 22.0,
    cruiseSpeed = 175.0,
    turnRate = 1.45,
    updateMs = 0,
    particleAsset = 'core',
    particleName = 'exp_grd_rpg_post',
    particleScale = 1.55
}

Config.Explosion = {
    count = 5,
    intervalMs = 420,
    radius = 22.0,
    type = 59,
    damageScale = 12.0,
    cameraShakeRange = 260.0,
    cameraShakeIntensity = 1.3
}

Config.Server = {
    launchCooldownMs = 10000
}

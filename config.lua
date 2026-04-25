Config = {}

-- Main launcher location in Sandy Shores
Config.LaunchSite = {
    coords = vector3(1880.52, 3690.84, 33.90),
    heading = 205.0,
    interactionDistance = 3.0,
    maxPlayerDistance = 35.0
}

-- Props (change these with your preferred custom assets if available)
Config.Models = {
    platform = 'prop_tool_bench02_ld',
    arm = 'prop_winch_hook_short',
    missile = 'w_lr_rpg_rocket',
    button = 'prop_ld_bomb_anim'
}

-- Relative offsets (based on launch platform)
Config.ArmOffset = vector3(0.0, -0.35, 1.1)
Config.MissileOffset = vector3(0.0, 0.0, 0.65)
Config.ButtonOffset = vector3(3.2, 1.0, 0.0)

Config.Rope = {
    enabled = true,
    length = 5.5,
    minLength = 1.5,
    timeMultiplier = 1.0
}

Config.Launch = {
    countdownSeconds = 3,
    cooldownSeconds = 120,
    armRaiseDuration = 2500,
    armStartPitch = -15.0,
    armReadyPitch = -70.0,
    missileInitialSpeed = 115.0,
    homingSpeed = 160.0,
    curveStartDelayMs = 2000,
    homingDurationMs = 11000,
    proximityDetonation = 8.0,
    maxTravelTimeMs = 15000,
    damageRadius = 24.0
}

Config.Effects = {
    launchCameraShake = {
        name = 'LARGE_EXPLOSION_SHAKE',
        intensity = 0.65,
        durationMs = 1100
    },
    launchSound = '5_SEC_WARNING',
    clickSound = 'SELECT',
    soundSet = 'HUD_MINI_GAME_SOUNDSET'
}

Config.Targets = {
    { name = 'Sandy Gas Station', coords = vector3(2006.25, 3773.45, 32.18) },
    { name = 'Alamo Docks', coords = vector3(1547.90, 3912.84, 30.90) },
    { name = 'Yellow Jack Rooftop', coords = vector3(1990.76, 3055.12, 47.21) },
    { name = 'Grapeseed Hangar', coords = vector3(2134.07, 4780.10, 40.97) }
}

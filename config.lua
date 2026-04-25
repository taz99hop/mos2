Config = {}

Config.Debug = false

Config.WarehouseCraftPoint = vector3(923.65, -1561.44, 30.74)
Config.WarehouseHeading = 268.0
Config.LaunchPad = {
    coords = vector3(931.52, -1531.28, 30.39),
    heading = 175.0
}

Config.TransportSpawnOffset = vector4(6.0, 0.0, 0.0, 90.0)
Config.TransportTruckModel = `hauler`

Config.MissileModels = {
    stage1 = `prop_air_bigradar_l1`,
    stage2 = `prop_air_bigradar_l2`,
    complete = `prop_air_bigradar`
}

Config.StageDurations = {
    total = 50000,
    stage1 = 16000,
    stage2 = 17000,
    stage3 = 17000
}

Config.Flight = {
    verticalTime = 5500,
    tiltTime = 3000,
    cruiseTime = 12000,
    maxVerticalBoost = 48.0,
    tiltHeightGain = 25.0,
    arcHeight = 80.0,
    tick = 50
}

Config.PredefinedTargets = {
    { label = 'مركز الشرطة الرئيسي', coords = vector3(441.21, -981.94, 30.69) },
    { label = 'مستشفى المدينة', coords = vector3(304.36, -584.82, 43.28) },
    { label = 'الميناء', coords = vector3(1207.36, -2978.79, 5.86) }
}

Config.Particles = {
    launchDict = 'core',
    launchName = 'exp_grd_bzgas_smoke',
    impactDict = 'core',
    impactName = 'exp_grd_flare'
}

Config.Sounds = {
    launch = '5_SEC_WARNING',
    launchRef = 'HUD_MINI_GAME_SOUNDSET',
    flight = 'TIMER_STOP',
    flightRef = 'HUD_MINI_GAME_SOUNDSET',
    impact = 'Bomb_Disarmed',
    impactRef = 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS'
}

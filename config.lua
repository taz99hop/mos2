Config = {}

Config.CommanderCitizenId = 'COMMANDER_CID_001'
Config.UseCommand = true
Config.OpenUiCommand = 'milcmd'
Config.TestingAllowAllPlayers = true -- للتجربة: أي لاعب يمكنه استخدام صلاحيات القائد

Config.MaxActiveMissiles = 40
Config.MaxClusterSubmunitions = 10
Config.ServerTickMs = 50
Config.SequentialDelayMin = 1000
Config.SequentialDelayMax = 2000

Config.RadarUpdateHz = 5
Config.InterceptorScanRadius = 1800.0
Config.AntiAirBatteries = {
    {
        id = 'AA_EAST',
        coords = vector3(1250.0, -450.0, 90.0),
        interceptChance = 0.62,
        maxShotsPerMinute = 20
    },
    {
        id = 'AA_WEST',
        coords = vector3(-950.0, 500.0, 80.0),
        interceptChance = 0.55,
        maxShotsPerMinute = 15
    }
}

Config.AirZones = {
    {
        name = 'LS_SAFE',
        type = 'safe',
        center = vector3(210.0, -920.0, 30.0),
        radius = 900.0
    },
    {
        name = 'BLAINE_COMBAT',
        type = 'combat',
        center = vector3(1600.0, 3800.0, 40.0),
        radius = 2200.0
    }
}

Config.TargetImpacts = {
    power_stations = {
        { name = 'LS_GRID_A', coords = vector3(708.0, 117.0, 80.0), radius = 120.0 }
    },
    radars = {
        { name = 'SANDY_RADAR', coords = vector3(1875.0, 3707.0, 33.0), radius = 100.0 }
    }
}

Config.MissileTypes = {
    HE = {
        label = 'شديد الانفجار (HE)',
        speed = 420.0,
        arcFactor = 0.22,
        gravity = 9.81,
        blastRadius = 22.0,
        damageScale = 1.0,
        deviationBase = 3.0,
        cluster = false
    },
    LONG_RANGE = {
        label = 'بعيد المدى',
        speed = 520.0,
        arcFactor = 0.32,
        gravity = 9.81,
        blastRadius = 28.0,
        damageScale = 1.25,
        deviationBase = 6.0,
        cluster = false
    },
    PRECISION = {
        label = 'دقيق',
        speed = 460.0,
        arcFactor = 0.24,
        gravity = 9.81,
        blastRadius = 20.0,
        damageScale = 0.95,
        deviationBase = 1.0,
        cluster = false
    },
    UNGUIDED = {
        label = 'غير موجه',
        speed = 400.0,
        arcFactor = 0.20,
        gravity = 9.81,
        blastRadius = 18.0,
        damageScale = 0.90,
        deviationBase = 12.0,
        cluster = false
    },
    CLUSTER = {
        label = 'انشطاري',
        speed = 430.0,
        arcFactor = 0.27,
        gravity = 9.81,
        blastRadius = 12.0,
        damageScale = 0.7,
        deviationBase = 5.0,
        cluster = true,
        splitAtProgress = 0.70,
        splitAltitude = 150.0,
        submunitionCount = 7,
        subSpreadRadius = 45.0
    }
}

Config.Visual = {
    missileModel = `w_lr_rpg_rocket`,
    launchFx = 'core',
    launchFxName = 'ent_sht_flame',
    splitFxName = 'ent_sht_electrical_box',
    smokeFxName = 'exp_grd_bzgas_smoke',
    launchSound = '5_SEC_WARNING',
    splitSound = 'CHECKPOINT_MISSED',
    sirenSound = 'TIMER_STOP'
}

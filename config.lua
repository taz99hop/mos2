Config = Config or {}

Config.Debug = false
Config.JobName = 'resistance'
Config.LeaderGradeName = 'leader'
Config.CommanderGradeName = 'commander'
Config.OperativeGradeName = 'operative'
Config.RecruitGradeName = 'recruit'

Config.General = {
    UseOxLibProgress = false,
    DefaultInteractionDistance = 2.0,
    PoliceJobNames = { ['police'] = true, ['sheriff'] = true },
    AnnouncementCooldownSeconds = 120,
    OnesyncRequired = true,
}

Config.Security = {
    ServerEventToken = 'RFS_EVT_V1',
    EnableWarehouseCode = true,
    RequiredWarehouseCodeLength = 4,
    SecretLocationMaskForNonMembers = true,
}

Config.Joining = {
    LeaderInviteCommand = 'resinvite',
    LeaderKickCommand = 'reskick',
}

Config.ManufacturingStations = {
    weapon_workshop = {
        label = 'ورشة الأسلحة',
        icon = 'fas fa-gun',
        coords = vec3(1400.84, 1139.32, 114.33),
        heading = 85.0,
        allowedRanks = { leader = true, commander = true, operative = true },
        animation = { dict = 'amb@prop_human_parking_meter@male@idle_a', clip = 'idle_a' },
        recipes = {
            {
                id = 'weapon_pistol',
                label = 'مسدس',
                duration = 12000,
                output = { item = 'weapon_pistol', amount = 1 },
                requirements = { metalscrap = 50, steel = 30, plastic = 20 },
                heat = 5,
            },
            {
                id = 'weapon_smg',
                label = 'رشاش',
                duration = 22000,
                output = { item = 'weapon_smg', amount = 1 },
                requirements = { metalscrap = 150, steel = 120, plastic = 50, rubber = 20 },
                heat = 15,
            },
            {
                id = 'pistol_ammo',
                label = 'ذخيرة',
                duration = 6000,
                output = { item = 'pistol_ammo', amount = 4 },
                requirements = { metalscrap = 15, copper = 10 },
                heat = 2,
            },
            {
                id = 'rocket_ammo',
                label = 'صاروخ RPG',
                duration = 30000,
                output = { item = 'rpg_ammo', amount = 1 },
                requirements = { steel = 100, aluminum = 80, plastic = 45, explosives = 2 },
                heat = 25,
            }
        }
    },
    electronics_table = {
        label = 'طاولة الإلكترونيات',
        icon = 'fas fa-microchip',
        coords = vec3(1394.56, 1138.55, 114.33),
        heading = 180.0,
        allowedRanks = { leader = true, commander = true, operative = true, recruit = true },
        animation = { dict = 'amb@world_human_stand_mobile@male@text@base', clip = 'base' },
        recipes = {
            {
                id = 'tracker_device',
                label = 'جهاز تتبع',
                duration = 9000,
                output = { item = 'tracker_device', amount = 1 },
                requirements = { electronickit = 1, copper = 20, plastic = 12 },
                heat = 4,
            },
            {
                id = 'radio_transmitter',
                label = 'جهاز إرسال',
                duration = 13000,
                output = { item = 'radio_transmitter', amount = 1 },
                requirements = { electronickit = 1, iron = 10, copper = 25, screwdriverset = 1 },
                heat = 6,
            },
            {
                id = 'drone_parts',
                label = 'قطع درون',
                duration = 18000,
                output = { item = 'drone_parts', amount = 1 },
                requirements = { aluminum = 40, copper = 35, plastic = 20, electronickit = 1 },
                heat = 8,
            }
        }
    },
    material_lab = {
        label = 'مختبر المواد',
        icon = 'fas fa-flask',
        coords = vec3(1398.61, 1131.78, 114.33),
        heading = 270.0,
        allowedRanks = { leader = true, commander = true, operative = true },
        animation = { dict = 'mini@repair', clip = 'fixing_a_player' },
        recipes = {
            {
                id = 'chipset',
                label = 'شرائح تقنية',
                duration = 10000,
                output = { item = 'chipset', amount = 2 },
                requirements = { silicon = 20, plastic = 10, copper = 5 },
                heat = 3,
            },
            {
                id = 'explosives',
                label = 'مواد متفجرة',
                duration = 20000,
                output = { item = 'explosives', amount = 1 },
                requirements = { sulfur = 30, charcoal = 20, fertilizer = 10 },
                heat = 18,
            }
        }
    }
}

Config.Missile = {
    LaunchConsole = vec3(1404.62, 1148.95, 114.33),
    LaunchRadius = 3000.0,
    CountdownSeconds = 10,
    CooldownSeconds = 900,
    PoliceBlipDurationSeconds = 90,
    PoliceBlipSprite = 161,
    PoliceBlipColor = 1,
    JamDurationSeconds = 120,
    SmokeDurationSeconds = 75,
    Types = {
        explosive = {
            label = 'صاروخ تفجيري',
            requiredItem = 'rpg_ammo',
            heat = 35,
            permissions = { leader = true },
        },
        jamming = {
            label = 'صاروخ تشويش',
            requiredItem = 'signal_jammer_missile',
            heat = 20,
            permissions = { leader = true },
        },
        smoke = {
            label = 'صاروخ دخاني',
            requiredItem = 'smoke_missile',
            heat = 10,
            permissions = { leader = true },
        }
    }
}

Config.Warehouses = {
    weapon_stash = {
        label = 'مستودع الأسلحة',
        coords = vec3(1370.83, 1147.28, 113.76),
        stashId = 'resistance_weapons',
        slots = 120,
        weight = 450000,
        minRank = 'commander',
        code = '2580',
    },
    material_stash = {
        label = 'مستودع المواد',
        coords = vec3(1369.22, 1131.90, 113.76),
        stashId = 'resistance_materials',
        slots = 200,
        weight = 600000,
        minRank = 'operative',
        code = '9315',
    }
}

Config.Garage = {
    PedSpawn = vec4(1412.89, 1119.41, 114.84, 90.0),
    SpawnPoint = vec4(1407.70, 1115.30, 114.84, 90.0),
    StorePoint = vec3(1414.06, 1112.11, 114.84),
    Vehicles = {
        recruit = {
            { model = 'rebel', label = 'Rebel (دورية)' }
        },
        operative = {
            { model = 'mesa3', label = 'Mesa Tactical' }
        },
        commander = {
            { model = 'insurgent', label = 'Insurgent' }
        },
        leader = {
            { model = 'barrage', label = 'Barrage Command' }
        }
    }
}

Config.Zones = {
    {
        id = 'sandy_shores',
        label = 'ساندي شورز',
        center = vec3(1834.0, 3662.0, 34.0),
        radius = 250.0,
        bonusMoney = 2500,
        captureTimeSeconds = 180,
        blipColorNeutral = 0,
        blipColorResistance = 1,
        blipColorPolice = 3,
    },
    {
        id = 'grapeseed',
        label = 'جريبسيد',
        center = vec3(1704.0, 4944.0, 42.0),
        radius = 220.0,
        bonusMoney = 2100,
        captureTimeSeconds = 160,
        blipColorNeutral = 0,
        blipColorResistance = 1,
        blipColorPolice = 3,
    }
}

Config.Heat = {
    DecayIntervalSeconds = 300,
    DecayAmount = 5,
    Thresholds = {
        low = 0,
        medium = 20,
        high = 45,
        emergency = 75,
    },
    LabelByLevel = {
        low = 'منخفض',
        medium = 'متوسط',
        high = 'عالي',
        emergency = 'حالة طوارئ',
    }
}

Config.Cinematic = {
    TriggerItem = 'leader_broadcast_card',
    DurationSeconds = 20,
    DefaultMessage = 'تحذير: يمنع دخول ساندي شورز',
    DefaultImage = 'https://i.imgur.com/iM4JvG8.jpeg',
    DefaultAudio = 'https://cdn.freesound.org/previews/458/458618_8386276-lq.mp3',
}

Config.Notifications = {
    UseQBCoreNotify = true,
}

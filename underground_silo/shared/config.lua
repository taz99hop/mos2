Config = {}

Config.Debug = false
Config.UseStateBags = true

Config.Framework = 'qb-core'
Config.Target = 'qb-target'

Config.CommandOpenPanel = 'silo'

Config.Base = {
    controlPanel = vec3(905.85, -3235.34, -98.25),
    hatchCenter = vec3(910.20, -3240.00, -98.10),
    surfaceZ = 14.40,
    heading = 180.0,
    hatchOpenZOffset = 1.85,
    elevatorBottomZ = -103.80,
    elevatorTopZ = 13.90,
    armPivotOffset = vec3(0.0, -1.05, 1.20),
    camera = {
        pos = vec3(914.0, -3245.0, 18.0),
        rot = vec3(-12.0, 0.0, 34.0),
        fov = 52.0
    }
}

Config.Models = {
    hatch = `prop_ld_bomb_anim`,
    elevator = `xm_prop_x17_sub_locker`,
    arm = `gr_prop_gr_rsply_crate04a`,
}

Config.Sequence = {
    hatchOpenMs = 8000,
    platformRiseMs = 22000,
    armPitchMs = 10000,
    armStartPitch = -91.0,
    armEndPitch = 0.0,
    heavyTickMs = 20
}

Config.Sounds = {
    siren = '5_SEC_WARNING',
    hatchSteam = 'Steam',
    heavyMotor = 'Crane_Move_Start',
    launch = 'DLC_XM_Explosions_Orbital_Cannon',
}

Config.Missiles = {
    tactical = {
        label = 'تكتيكي',
        prop = `w_lr_rpg_rocket`,
        offset = vec3(0.00, 0.15, -0.02),
        rot = vec3(0.0, 0.0, 90.0),
        speed = 420.0,
        impactRadius = 20.0,
        baseDamage = 350,
        flightTrail = 'core',
        flightFx = 'ent_sht_rocket'
    },
    emp = {
        label = 'EMP',
        prop = `w_lr_rpg_rocket`,
        offset = vec3(0.00, 0.14, -0.03),
        rot = vec3(0.0, 0.0, 90.0),
        speed = 370.0,
        impactRadius = 30.0,
        baseDamage = 200,
        flightTrail = 'core',
        flightFx = 'ent_sht_rocket'
    },
    chemical = {
        label = 'كيميائي',
        prop = `w_lr_rpg_rocket`,
        offset = vec3(0.00, 0.18, -0.03),
        rot = vec3(0.0, 0.0, 90.0),
        speed = 300.0,
        impactRadius = 38.0,
        baseDamage = 180,
        flightTrail = 'core',
        flightFx = 'ent_sht_rocket'
    },
    nuclear = {
        label = 'نووي ICBM',
        prop = `w_lr_rpg_rocket`,
        offset = vec3(0.00, 0.20, -0.05),
        rot = vec3(0.0, 0.0, 90.0),
        speed = 250.0,
        impactRadius = 110.0,
        baseDamage = 1200,
        flightTrail = 'core',
        flightFx = 'ent_sht_rocket'
    }
}

Config.CleanupAfterMs = 140000
Config.ChemicalDurationMs = 45000
Config.EmpDurationMs = 25000

Config.AuthorizedJobs = {
    ['police'] = true,
    ['army'] = true,
    ['government'] = true,
}

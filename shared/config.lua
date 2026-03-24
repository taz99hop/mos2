Config = {}

-- Vehicle model that can open and use the missile system
Config.TruckModel = `m142`

-- Missile prop model from your resource files
Config.MissileModel = `w_lr_himars`

-- How many missiles per full launch cycle
Config.DefaultMissileCount = 6

-- Delay between missiles (ms)
Config.MissileDelay = 750

-- Radius random spread around marked target (meters)
Config.SpreadRadius = 8.0

-- Max range from launcher truck to target marker (meters)
Config.MaxLaunchRange = 2200.0

-- Cooldown after a launch cycle (seconds)
Config.CooldownSeconds = 45

-- Require driver seat for controls
Config.RequireDriverSeat = true

-- If true, only specific jobs can launch
Config.JobLocked = false
Config.AllowedJobs = {
    ['police'] = 2,
    ['army'] = 0,
    ['sheriff'] = 3
}

-- UI open key while in truck
Config.OpenUiKey = 'F6'

-- Optional item required in inventory
Config.RequireLaunchCard = false
Config.LaunchCardItem = 'launch_card'

-- Visual/audio flavor
Config.ScreenShake = true
Config.ScreenShakeStrength = 0.5
Config.ScreenShakeDurationMs = 2000
Config.LaunchSound = 'DLC_XM_Explosions_Cluster_Bomb'
Config.LaunchSoundSet = 'DLC_XM_Explosions_Sounds'

-- Limits
Config.MinMissiles = 1
Config.MaxMissiles = 12

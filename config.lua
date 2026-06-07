Config = {}

-- Civilian plane model (non-military)
Config.PlaneModel = `shamal`
Config.PilotModel = `s_m_m_pilot_02`

-- Number of planes to spawn
Config.PlaneCount = 20

-- Spawn area above Paleto Bay / Mount Chiliad
Config.SpawnCenter = vector3(-210.0, 6500.0, 1300.0)
Config.SpawnRadius = 400.0

-- Safe high altitude to avoid mountain collisions
Config.CruiseAltitude = 1250.0

-- Start spawning after resource start delay (ms)
Config.StartDelay = 5000

-- Targets across Los Santos and nearby areas.
Config.Targets = {
    vector3(1222.0, -3007.0, 45.0),  -- Port of LS
    vector3(425.1, -979.5, 45.0),    -- Mission Row PD
    vector3(-1037.0, -2738.0, 45.0), -- LSIA
    vector3(1706.0, 3260.0, 90.0),   -- Sandy Airfield area
    vector3(812.0, -1278.0, 60.0),   -- Cypress Flats
    vector3(-75.0, -818.0, 120.0),   -- Downtown
    vector3(-545.0, -201.0, 120.0),  -- Rockford area
    vector3(2528.0, -383.0, 120.0),  -- East coast LS county
    vector3(-2188.0, 3270.0, 90.0),  -- Pacific coast north
    vector3(1823.0, 2604.0, 80.0),   -- Prison area
    vector3(146.0, 6631.0, 220.0),   -- Paleto ridge return lane
    vector3(-1568.0, 2763.0, 110.0), -- Raton Canyon
    vector3(-1295.0, -3053.0, 70.0), -- Del Perro coast
    vector3(266.0, -3328.0, 70.0),   -- Elysian approach
    vector3(1138.0, -2288.0, 70.0),  -- Murrieta Oil Field
    vector3(-428.0, 6023.0, 250.0),  -- Chiliad flank
    vector3(2868.0, 4459.0, 220.0),  -- Tataviam route
    vector3(-819.0, 5408.0, 230.0),  -- Mount Josiah
    vector3(172.0, -231.0, 130.0),   -- Pillbox skyline
    vector3(-183.0, -2629.0, 80.0)   -- La Puerta
}

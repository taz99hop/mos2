Ballistics = {}

local function vecSub(a, b)
    return vector3(a.x - b.x, a.y - b.y, a.z - b.z)
end

local function vecAdd(a, b)
    return vector3(a.x + b.x, a.y + b.y, a.z + b.z)
end

local function vecMul(a, s)
    return vector3(a.x * s, a.y * s, a.z * s)
end

local function vecLen(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

local function vecNorm(v)
    local len = vecLen(v)
    if len < 0.0001 then
        return vector3(0.0, 0.0, 0.0)
    end
    return vector3(v.x / len, v.y / len, v.z / len)
end

function Ballistics.solveLaunch(origin, target, spec)
    local delta = vecSub(target, origin)
    local horizontal = vector3(delta.x, delta.y, 0.0)
    local distance = vecLen(horizontal)

    local baseTime = math.max(distance / spec.speed, 0.1)
    local arcBonus = distance * spec.arcFactor / math.max(spec.speed, 1.0)
    local timeOfFlight = baseTime + arcBonus

    local vx = delta.x / timeOfFlight
    local vy = delta.y / timeOfFlight
    local vz = (delta.z + 0.5 * spec.gravity * timeOfFlight * timeOfFlight) / timeOfFlight

    local launchVelocity = vector3(vx, vy, vz)
    local launchSpeed = vecLen(launchVelocity)
    local pitchDeg = math.deg(math.atan2(vz, math.sqrt(vx * vx + vy * vy)))

    local apexTime = vz / spec.gravity
    local apex = vecAdd(origin, vecMul(launchVelocity, apexTime))
    apex = vector3(apex.x, apex.y, apex.z - 0.5 * spec.gravity * apexTime * apexTime)

    return {
        timeOfFlight = timeOfFlight,
        launchVelocity = launchVelocity,
        launchSpeed = launchSpeed,
        pitchDeg = pitchDeg,
        apex = apex,
        distance = distance
    }
end

function Ballistics.positionAt(origin, velocity, gravity, t)
    return vector3(
        origin.x + velocity.x * t,
        origin.y + velocity.y * t,
        origin.z + velocity.z * t - 0.5 * gravity * t * t
    )
end

function Ballistics.velocityAt(velocity0, gravity, t)
    return vector3(velocity0.x, velocity0.y, velocity0.z - gravity * t)
end

function Ballistics.bearingFromVelocity(v)
    local heading = math.deg(math.atan2(v.y, v.x))
    if heading < 0.0 then
        heading = heading + 360.0
    end
    return heading
end

function Ballistics.applyDeviation(target, distance, deviationBase)
    local spread = deviationBase * (1.0 + (distance / 3000.0))
    local angle = math.rad(math.random() * 360.0)
    local radius = math.random() * spread
    return vector3(
        target.x + math.cos(angle) * radius,
        target.y + math.sin(angle) * radius,
        target.z
    )
end

function Ballistics.randomSubTargets(center, count, spreadRadius)
    local targets = {}
    for i = 1, count do
        local angle = math.rad((360.0 / count) * i + math.random(-12, 12))
        local radius = (spreadRadius * 0.55) + math.random() * (spreadRadius * 0.45)
        targets[#targets + 1] = vector3(
            center.x + math.cos(angle) * radius,
            center.y + math.sin(angle) * radius,
            center.z
        )
    end
    return targets
end

function Ballistics.clamp(value, minv, maxv)
    if value < minv then return minv end
    if value > maxv then return maxv end
    return value
end

function Ballistics.normalize(v)
    return vecNorm(v)
end

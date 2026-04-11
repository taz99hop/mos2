Resistance = Resistance or {}

Resistance.RankOrder = {
    recruit = 1,
    operative = 2,
    commander = 3,
    leader = 4,
}

function Resistance.GetGradeName(PlayerData)
    if not PlayerData or not PlayerData.job or PlayerData.job.name ~= Config.JobName then
        return nil
    end

    if PlayerData.job.grade and PlayerData.job.grade.name then
        return PlayerData.job.grade.name
    end

    if PlayerData.job.grade and PlayerData.job.grade.level then
        local lvl = PlayerData.job.grade.level
        if lvl >= 3 then
            return 'leader'
        elseif lvl == 2 then
            return 'commander'
        elseif lvl == 1 then
            return 'operative'
        else
            return 'recruit'
        end
    end

    return 'recruit'
end

function Resistance.HasMinRank(currentRank, requiredRank)
    return (Resistance.RankOrder[currentRank] or 0) >= (Resistance.RankOrder[requiredRank] or 99)
end

function Resistance.HasAccessByMap(currentRank, allowedMap)
    return allowedMap and allowedMap[currentRank] == true
end

function Resistance.IsPolice(jobName)
    return Config.General.PoliceJobNames[jobName] == true
end

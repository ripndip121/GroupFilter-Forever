GroupFilterForeverFilter = {}

local roleKeys = {
    TANK = "tank",
    HEALER = "healer",
    DAMAGER = "dps",
}

function GroupFilterForeverFilter.Matches(info, player, role, class, excludedClasses)
    if not info or info.numMembers ~= 1 or info.hasSelf or info.isDelisted then
        return false
    end
    if class ~= "ALL" and (not player or player.classFilename ~= class) then
        return false
    end
    if player and player.classFilename and excludedClasses and excludedClasses[player.classFilename] then
        return false
    end
    if role ~= "ALL" then
        local key = roleKeys[role]
        if not key or not player or not player.lfgRoles or not player.lfgRoles[key] then
            return false
        end
    end
    return true
end

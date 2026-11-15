local roleOptions = {
    { value = "ALL", label = "All roles" },
    { value = "TANK", label = TANK or "Tank" },
    { value = "HEALER", label = HEALER or "Healer" },
    { value = "DAMAGER", label = DAMAGER or "Damage" },
}

local selectedRole, selectedClass = "ALL", "ALL"
local excludedClasses = {}
local page, pageSize = 1, 8
local rows, matches = {}, {}
local panel, status, pageText, previousButton, nextButton
local refresh

local function isSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function inviteAction(entry)
    if not entry or not LFGBrowseUtil_GetInviteActionForResult then
        return nil
    end
    local info = C_LFGList.GetSearchResultInfo(entry.id)
    if isSecret(info) or not info or isSecret(info.numMembers)
        or isSecret(info.hasSelf) or isSecret(info.isDelisted) or isSecret(info.leaderName) then
        return nil
    end
    if info.numMembers ~= 1 or info.hasSelf or info.isDelisted or info.leaderName ~= entry.name then
        return nil
    end
    local _, action = LFGBrowseUtil_GetInviteActionForResult(entry.id)
    return action
end

local function newLabel(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function render()
    local pages = math.max(1, math.ceil(#matches / pageSize))
    page = math.min(page, pages)
    for i, row in ipairs(rows) do
        local entry = matches[(page - 1) * pageSize + i]
        row.entry = entry
        if entry then
            row.name:SetText(entry.name)
            row.level:SetText(entry.level)
            row.details:SetText(entry.details)
            if row.location then
                row.location:SetText(entry.location or "")
            end
            local color = entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
            row.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
            row.level:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
            row.details:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
            if row.location then
                row.location:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
            end
            row.invite:SetEnabled(inviteAction(entry) ~= nil)
            row:Show()
        else
            row:Hide()
        end
    end
    pageText:SetText(page .. " / " .. pages)
    previousButton:SetEnabled(page > 1)
    nextButton:SetEnabled(page < pages)
end

local function hasSecretData(info, player)
    if isSecret(info) or isSecret(player) then
        return true
    end
    if info and (isSecret(info.numMembers) or isSecret(info.hasSelf)
        or isSecret(info.isDelisted) or isSecret(info.leaderName)) then
        return true
    end
    if player and (isSecret(player.classFilename) or isSecret(player.lfgRoles)) then
        return true
    end
    local roles = player and player.lfgRoles
    return roles and (isSecret(roles.tank) or isSecret(roles.healer) or isSecret(roles.dps))
end

local function roleText(roles)
    if not roles then
        return "Role unknown"
    end
    local names = {}
    if roles.tank then table.insert(names, "Tank") end
    if roles.healer then table.insert(names, "Healer") end
    if roles.dps then table.insert(names, "Damage") end
    return #names > 0 and table.concat(names, ", ") or "Role unknown"
end

refresh = function()
    if not panel or not panel:IsVisible() then
        return
    end
    matches = {}
    if LFGBrowseFrame.searching then
        status:SetText("Searching...")
        render()
        return
    end
    if LFGBrowseFrame.searchFailed then
        status:SetText("Search failed. Use Refresh in Group Finder.")
        render()
        return
    end

    local _, results = C_LFGList.GetFilteredSearchResults()
    local restricted, unavailable, levelRestricted = false, false, false
    for _, id in ipairs(results) do
        local info = C_LFGList.GetSearchResultInfo(id)
        if isSecret(info) then
            restricted = true
        elseif info then
            local player = C_LFGList.GetSearchResultPlayerInfo(id, 1)
            if hasSecretData(info, player) then
                restricted = true
            elseif GroupFilterForeverFilter.Matches(info, player, selectedRole, selectedClass, excludedClasses) then
                if not info.leaderName or info.leaderName == "" then
                    unavailable = true
                else
                    local className = player and player.classFilename
                    className = className and LOCALIZED_CLASS_NAMES_MALE[className] or "Unknown class"
                    local level = player and player.level
                    local levelText = "Lv ?"
                    if isSecret(level) then
                        levelRestricted = true
                    elseif type(level) == "number" and level > 0 then
                        levelText = (LEVEL_ABBR or "Lv") .. " " .. level
                    end
                    local location = "Unknown"
                    if player then
                        local areaName = player.areaName
                        if not isSecret(areaName) and areaName and areaName ~= "" then
                            location = areaName
                        end
                    end
                    table.insert(matches, {
                        id = id,
                        name = info.leaderName,
                        level = levelText,
                        location = location,
                        class = player and player.classFilename,
                        details = className .. " - " .. roleText(player and player.lfgRoles),
                    })
                end
            end
        else
            unavailable = true
        end
    end

    if restricted then
        status:SetText("Some data is restricted; results may be incomplete.")
    elseif unavailable then
        status:SetText("Some listings are unavailable.")
    elseif levelRestricted then
        status:SetText("Some player levels are restricted.")
    else
        status:SetText(#matches .. " matching solo players")
    end
    render()
end

local function createDropdown(parent, options, getValue, setValue, x, y)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", x, y)
    dropdown:SetWidth(190)
    dropdown:SetupMenu(function(_, root)
        for _, option in ipairs(options) do
            root:CreateRadio(option.label, function()
                return getValue() == option.value
            end, function()
                setValue(option.value)
                page = 1
                refresh()
            end)
        end
    end)
    return dropdown
end

local function initialize()
    if panel then return end
    if not LFGBrowseFrame or not C_LFGList or not C_LFGList.GetSearchResultPlayerInfo
        or not LFGBrowseUtil_GetInviteActionForResult then
        print("|cffff4444GroupFilter-Forever:|r This client does not expose the expected Group Finder API.")
        return
    end

    panel = CreateFrame("Frame", nil, LFGBrowseFrame, "BackdropTemplate")
    panel:SetSize(520, 410)
    panel:SetPoint("TOPLEFT", LFGBrowseFrame, "TOPRIGHT", 120, -20)
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    panel:SetBackdropColor(1, 1, 1, 1)
    panel:SetBackdropBorderColor(1, 1, 1, 1)
    
    local title = newLabel(panel, "GroupFilter-Forever - Solo players", 20, -18, 480)
    title:SetTextColor(1, 0.84, 0, 1)
    title:SetFontObject(GameFontBold)

    createDropdown(panel, roleOptions, function() return selectedRole end,
        function(value) selectedRole = value end, 20, -44)
    local classes = { { value = "ALL", label = "All classes" } }
    for _, class in ipairs(CLASS_SORT_ORDER) do
        local name = LOCALIZED_CLASS_NAMES_MALE[class]
        if name then table.insert(classes, { value = class, label = name }) end
    end
    createDropdown(panel, classes, function() return selectedClass end,
        function(value) selectedClass = value end, 20, -76)

    local excludeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    excludeButton:SetSize(200, 22)
    excludeButton:SetPoint("TOPLEFT", 20, -108)
    excludeButton:SetText("Hide classes...")
    excludeButton:SetScript("OnClick", function(button)
        MenuUtil.CreateContextMenu(button, function(_, root)
            for index = 2, #classes do
                local option = classes[index]
                root:CreateCheckbox(option.label, function()
                    return excludedClasses[option.value] == true
                end, function()
                    excludedClasses[option.value] = not excludedClasses[option.value]
                    page = 1
                    refresh()
                end)
            end
        end)
    end)

    status = newLabel(panel, "", 20, -140, 480)
    status:SetFontObject(GameFontHighlightSmall)
    status:SetTextColor(0.2, 1, 0.2, 1)
    status:SetHeight(20)
    
    local headerRow = CreateFrame("Frame", nil, panel)
    headerRow:SetSize(480, 20)
    headerRow:SetPoint("TOPLEFT", 20, -166)
    local headerNames = {"Player Name", "Invite", "Lv", "Location / Zone", "Class - Roles"}
    local headerX = {0, 85, 145, 190, 295}
    local headerWidths = {80, 55, 40, 100, 180}
    for i, name in ipairs(headerNames) do
        local header = newLabel(headerRow, name, headerX[i], 0, headerWidths[i])
        header:SetTextColor(1, 0.84, 0, 1)
        header:SetFontObject(GameFontHighlightSmall)
    end
    for i = 1, pageSize do
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(480, 20)
        row:SetPoint("TOPLEFT", 20, -185 - (i - 1) * 21)
        row.name = newLabel(row, "", 0, 0, 80)
        row.name:SetFontObject(GameFontHighlightSmall)
        row.invite = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.invite:SetSize(55, 20)
        row.invite:SetPoint("TOPLEFT", 85, 2)
        row.invite:SetText(INVITE or "Invite")
        row.invite:SetScript("OnClick", function()
            local action = inviteAction(row.entry)
            if action then
                action()
            else
                print("|cffff4444GroupFilter-Forever:|r This player is no longer available to invite.")
                refresh()
            end
        end)
        row.level = newLabel(row, "", 145, 0, 40)
        row.level:SetFontObject(GameFontHighlightSmall)
        row.location = newLabel(row, "", 190, 0, 100)
        row.location:SetFontObject(GameFontHighlightSmall)
        row.details = newLabel(row, "", 295, 0, 180)
        row.details:SetFontObject(GameFontHighlightSmall)
        rows[i] = row
    end

    previousButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previousButton:SetSize(90, 24)
    previousButton:SetPoint("BOTTOMLEFT", 20, 20)
    previousButton:SetText("Previous")
    previousButton:SetScript("OnClick", function() page = page - 1; render() end)
    nextButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    nextButton:SetSize(90, 24)
    nextButton:SetPoint("BOTTOMRIGHT", -20, 20)
    nextButton:SetText("Next")
    nextButton:SetScript("OnClick", function() page = page + 1; render() end)
    pageText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pageText:SetPoint("BOTTOM", 0, 26)
    pageText:SetTextColor(1, 0.84, 0, 1)
    panel:SetScript("OnShow", refresh)
    if LFGBrowse_DoSearch then
        hooksecurefunc("LFGBrowse_DoSearch", refresh)
    end
    refresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
events:RegisterEvent("LFG_LIST_SEARCH_FAILED")
events:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PARTY_LEADER_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == "Blizzard_GroupFinder_VanillaStyle" then 
            initialize() 
        end
    else
        C_Timer.After(0, refresh)
    end
end)

if LFGBrowseFrame then initialize() end
print("|cff00ff00GroupFilter-Forever loaded successfully.|r")

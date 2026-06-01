--[[ NoRuski
     Automatically declines PENDING Premade Group Finder (LFG) applications from
     players whose names are written using the Cyrillic alphabet, but only while
     you are the host / leader of the listing.
     Verified against the World of Warcraft: Midnight 12.0.5 client API.
]]--

local ADDON_NAME = ...

local defaults = {
    enabled = true,
    announce = true,
}

NoRuskiDB = NoRuskiDB or {}

local function ApplyDefaults()
    for k, v in pairs(defaults) do
        if NoRuskiDB[k] == nil then
            NoRuskiDB[k] = v
        end
    end
end

-- Decode the next UTF-8 codepoint in `s` starting at byte index `i`.
-- Returns codepoint, nextIndex. Returns nil when out of range.
local function NextCodepoint(s, i)
    local b = s:byte(i)
    if not b then return nil end

    if b < 0x80 then
        return b, i + 1
    elseif b >= 0xF0 then
        local b2, b3, b4 = s:byte(i + 1), s:byte(i + 2), s:byte(i + 3)
        if not (b2 and b3 and b4) then return b, i + 1 end
        return ((b - 0xF0) * 0x40000)
             + ((b2 - 0x80) * 0x1000)
             + ((b3 - 0x80) * 0x40)
             +  (b4 - 0x80), i + 4
    elseif b >= 0xE0 then
        local b2, b3 = s:byte(i + 1), s:byte(i + 2)
        if not (b2 and b3) then return b, i + 1 end
        return ((b - 0xE0) * 0x1000)
             + ((b2 - 0x80) * 0x40)
             +  (b3 - 0x80), i + 3
    elseif b >= 0xC0 then
        local b2 = s:byte(i + 1)
        if not b2 then return b, i + 1 end
        return ((b - 0xC0) * 0x40) + (b2 - 0x80), i + 2
    else
        -- Stray continuation byte; skip it.
        return b, i + 1
    end
end

local function IsCyrillicCodepoint(cp)
    return (cp >= 0x0400 and cp <= 0x04FF)   -- Cyrillic
        or (cp >= 0x0500 and cp <= 0x052F)   -- Cyrillic Supplement
        or (cp >= 0x2DE0 and cp <= 0x2DFF)   -- Cyrillic Extended-A
        or (cp >= 0xA640 and cp <= 0xA69F)   -- Cyrillic Extended-B
        or (cp >= 0x1C80 and cp <= 0x1C8F)   -- Cyrillic Extended-C
end

-- Returns true if the name contains at least one Cyrillic character.
local function HasCyrillic(name)
    if not name then return false end
    local i, cp = 1
    while true do
        cp, i = NextCodepoint(name, i)
        if not cp then break end
        if IsCyrillicCodepoint(cp) then
            return true
        end
    end
    return false
end

local function Announce(fmt, ...)
    if NoRuskiDB.announce then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4040NoRuski|r: " .. fmt:format(...))
    end
end

-- We may only manage applicants when we own an active listing and, if grouped,
-- are the group leader.
local function AmIHosting()
    if not (C_LFGList and C_LFGList.HasActiveEntryInfo) then return false end
    if not C_LFGList.HasActiveEntryInfo() then return false end
    if IsInGroup() and not UnitIsGroupLeader("player") then return false end
    return true
end

-- Scan every pending applicant and decline any whose group contains a Cyrillic
-- name. Declining the application removes all of its members.
local function ProcessApplicants()
    if not NoRuskiDB.enabled then return end
    if not AmIHosting() then return end

    local applicants = C_LFGList.GetApplicants()
    if not applicants then return end

    for _, applicantID in ipairs(applicants) do
        local info = C_LFGList.GetApplicantInfo(applicantID)
        -- Only touch genuinely pending applications; never override an
        -- invite/decline we've already issued (pendingStatus ~= nil).
        if info and info.status == "applied" and info.pendingStatus == nil then
            local numMembers = info.numMembers or 1
            local hitName
            for memberIdx = 1, numMembers do
                local name = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
                if HasCyrillic(name) then
                    hitName = name
                    break
                end
            end
            if hitName then
                C_LFGList.DeclineApplicant(applicantID)
                Announce("Declined LFG applicant %s.", hitName)
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
frame:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == ADDON_NAME then
            ApplyDefaults()
        end
        return
    end

    -- Both applicant events mean the pending list may have changed.
    ProcessApplicants()
end)

-- Slash commands -----------------------------------------------------------
SLASH_NORUSKI1 = "/noruski"
SLASH_NORUSKI2 = "/nr"
SlashCmdList["NORUSKI"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "on" then
        NoRuskiDB.enabled = true
        Announce("Enabled.")
    elseif msg == "off" then
        NoRuskiDB.enabled = false
        Announce("Disabled.")
    elseif msg == "announce" then
        NoRuskiDB.announce = not NoRuskiDB.announce
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4040NoRuski|r: announcements " ..
            (NoRuskiDB.announce and "ON" or "OFF") .. ".")
    elseif msg == "scan" then
        ProcessApplicants()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4040NoRuski|r: scanned current applicants.")
    elseif msg:match("^test ") then
        local name = msg:gsub("^test%s+", "")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4040NoRuski|r: '" .. name .. "' -> " ..
            (HasCyrillic(name) and "Cyrillic (would decline)" or "not Cyrillic"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4040NoRuski|r commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /noruski on|off  - enable/disable auto-declining")
        DEFAULT_CHAT_FRAME:AddMessage("  /noruski scan    - re-check current LFG applicants now")
        DEFAULT_CHAT_FRAME:AddMessage("  /noruski announce - toggle chat announcements")
        DEFAULT_CHAT_FRAME:AddMessage("  /noruski test <name> - check if a name is Cyrillic")
        DEFAULT_CHAT_FRAME:AddMessage(("  status: %s | announce:%s"):format(
            NoRuskiDB.enabled and "ON" or "OFF",
            NoRuskiDB.announce and "ON" or "OFF"))
    end
end

local ADDON_NAME, ns = ...

-- Public-ish namespace shared by Core.lua, Pulse.lua, and UI.lua. The table is
-- private to this addon; nothing is added to _G.
ns.name = ADDON_NAME
ns.version = "0.1.0"
ns.PREFIX = "|cff33ff99HousingNudge|r"

local aceLocale = LibStub and LibStub("AceLocale-3.0")
local L = aceLocale and aceLocale:GetLocale(ADDON_NAME)
if not L then
    L = setmetatable({}, { __index = function(_, key) return key end })
end
ns.L = L

local DB_DEFAULTS = {
    version = 1,
    steps = 5,
    debug = false,
    frame = {
        point = "CENTER",
        relPoint = "CENTER",
        x = 0,
        y = 0,
    },
}

local VALID_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

-- User-facing names map to enum field names, not numeric values. The actual
-- enum table is read lazily so a client without the housing API still loads.
local INCREMENT_SPECS = {
    left = { enumKey = "Left", submodeKey = "Translate" },
    right = { enumKey = "Right", submodeKey = "Translate" },
    forward = { enumKey = "Forward", submodeKey = "Translate" },
    back = { enumKey = "Back", submodeKey = "Translate" },
    up = { enumKey = "Up", submodeKey = "Translate" },
    down = { enumKey = "Down", submodeKey = "Translate" },
    rotateleft = { enumKey = "RotateLeft", submodeKey = "Rotate" },
    rotateright = { enumKey = "RotateRight", submodeKey = "Rotate" },
    scaleup = { enumKey = "ScaleUp", submodeKey = "Scale" },
    scaledown = { enumKey = "ScaleDown", submodeKey = "Scale" },
}

local incrementCache

function ns:Print(message)
    local text = self.PREFIX .. " " .. tostring(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    else
        print(text)
    end
end

function ns:Debug(message)
    if self.db and self.db.debug then
        self:Print("debug: " .. tostring(message))
    end
end

local function mergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            mergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local function sanitizeNumber(value, fallback)
    if type(value) ~= "number" then
        return fallback
    end
    return value
end

function ns:SanitizeDB()
    local db = self.db
    if not db then
        return
    end

    if type(db.version) ~= "number" then
        db.version = DB_DEFAULTS.version
    end

    db.steps = sanitizeNumber(db.steps, DB_DEFAULTS.steps)
    db.steps = math.floor(db.steps)
    if db.steps < 1 then
        db.steps = 1
    elseif db.steps > 60 then
        db.steps = 60
    end

    if type(db.debug) ~= "boolean" then
        db.debug = DB_DEFAULTS.debug
    end

    if type(db.frame) ~= "table" then
        db.frame = {}
        mergeDefaults(db.frame, DB_DEFAULTS.frame)
    end

    if not VALID_POINTS[db.frame.point] then
        db.frame.point = DB_DEFAULTS.frame.point
    end
    if not VALID_POINTS[db.frame.relPoint] then
        db.frame.relPoint = DB_DEFAULTS.frame.relPoint
    end
    db.frame.x = sanitizeNumber(db.frame.x, DB_DEFAULTS.frame.x)
    db.frame.y = sanitizeNumber(db.frame.y, DB_DEFAULTS.frame.y)
end

function ns:InitDB()
    if type(HousingNudgeDB) ~= "table" then
        HousingNudgeDB = {}
    end
    mergeDefaults(HousingNudgeDB, DB_DEFAULTS)
    self.db = HousingNudgeDB
    self:SanitizeDB()
end

function ns:ResetDB()
    HousingNudgeDB = {}
    mergeDefaults(HousingNudgeDB, DB_DEFAULTS)
    self.db = HousingNudgeDB
    self:SanitizeDB()

    if ns.UI and ns.UI.ResetPosition then
        ns.UI:ResetPosition()
    end
end

local function buildIncrementMap()
    local housingEnum = Enum and Enum.HousingIncrementType
    if type(housingEnum) ~= "table" then
        return nil
    end

    local map = {}
    for name, spec in pairs(INCREMENT_SPECS) do
        local enumValue = housingEnum[spec.enumKey]
        if enumValue ~= nil then
            map[name] = {
                enum = enumValue,
                submodeKey = spec.submodeKey,
            }
        end
    end
    return map
end

function ns:GetIncrementMap()
    if incrementCache then
        return incrementCache
    end

    local map = buildIncrementMap()
    if map then
        incrementCache = map
        return map
    end

    return {}
end

function ns:GetIncrementType(name)
    if type(name) ~= "string" then
        return nil
    end

    local entry = self:GetIncrementMap()[string.lower(name)]
    return entry and entry.enum or nil
end

function ns:GetIncrementName(incrementType)
    if incrementType == nil then
        return "nil"
    end

    for name, entry in pairs(self:GetIncrementMap()) do
        if entry.enum == incrementType then
            return name
        end
    end
    return tostring(incrementType)
end

function ns:GetSubmodeForIncrement(incrementType)
    if incrementType == nil then
        return nil
    end

    local submodeEnum = Enum and Enum.HousingPrecisionSubmode
    if type(submodeEnum) ~= "table" then
        return nil
    end

    for _, entry in pairs(self:GetIncrementMap()) do
        if entry.enum == incrementType then
            return submodeEnum[entry.submodeKey]
        end
    end
    return nil
end

function ns:IsApiAvailable()
    if type(C_HousingExpertMode) ~= "table" then
        return false, "C_HousingExpertMode is missing"
    end
    if type(C_HousingExpertMode.SetPrecisionIncrementingActive) ~= "function" then
        return false, "C_HousingExpertMode.SetPrecisionIncrementingActive is missing"
    end
    if type(Enum) ~= "table" or type(Enum.HousingIncrementType) ~= "table" then
        return false, "Enum.HousingIncrementType is missing"
    end
    if type(C_HouseEditor) ~= "table" then
        return false, "C_HouseEditor is missing"
    end
    if type(C_HouseEditor.IsHouseEditorActive) ~= "function" then
        return false, "C_HouseEditor.IsHouseEditorActive is missing"
    end
    return true
end

function ns:GetSubmode()
    if type(C_HousingExpertMode) ~= "table" then
        return nil
    end
    if type(C_HousingExpertMode.GetPrecisionSubmode) ~= "function" then
        return nil
    end

    local ok, submode = pcall(C_HousingExpertMode.GetPrecisionSubmode)
    if not ok then
        return nil
    end
    return submode
end

function ns:GetSubmodeName(submode)
    local submodeEnum = Enum and Enum.HousingPrecisionSubmode
    if submode == nil or type(submodeEnum) ~= "table" then
        return "unknown"
    end
    if submode == submodeEnum.Translate then
        return "Translate"
    elseif submode == submodeEnum.Rotate then
        return "Rotate"
    elseif submode == submodeEnum.Scale then
        return "Scale"
    end
    return "unknown"
end

function ns:IsHouseEditorActive()
    if type(C_HouseEditor) ~= "table" then
        return nil
    end
    if type(C_HouseEditor.IsHouseEditorActive) ~= "function" then
        return nil
    end

    local ok, active = pcall(C_HouseEditor.IsHouseEditorActive)
    if not ok then
        return nil
    end
    return active and true or false
end

function ns:IsDecorSelected()
    if type(C_HousingExpertMode) ~= "table" then
        return nil
    end
    if type(C_HousingExpertMode.IsDecorSelected) ~= "function" then
        return nil
    end

    local ok, selected = pcall(C_HousingExpertMode.IsDecorSelected)
    if not ok then
        return nil
    end
    return selected and true or false
end

function ns:IsExpertDecorMode()
    local modeEnum = Enum and Enum.HouseEditorMode
    if type(modeEnum) ~= "table" then
        return false
    end

    -- HOUSE_EDITOR_MODE_CHANGED is the authoritative source while the editor is
    -- open. There is no current-mode getter in the documented API, so fall back
    -- to a non-nil precision submode, which only exists in Expert Decor mode.
    if self.editorMode ~= nil then
        return self.editorMode == modeEnum.ExpertDecor
    end

    return self:GetSubmode() ~= nil
end

function ns:CanPulse()
    local available, reason = self:IsApiAvailable()
    if not available then
        return false, reason
    end

    local editorActive = self:IsHouseEditorActive()
    if editorActive == nil then
        return false, L["Could not read the house editor state."]
    end
    if not editorActive then
        return false, L["Open the House Editor first."]
    end

    if not self:IsExpertDecorMode() then
        return false, L["Enter Expert Decor mode."]
    end

    local selected = self:IsDecorSelected()
    if selected == nil then
        return false, L["Could not read the decor selection."]
    end
    if not selected then
        return false, L["Select a decor item."]
    end

    if InCombatLockdown and InCombatLockdown() then
        return false, L["Cannot pulse during combat lockdown."]
    end

    return true
end

function ns:GetStatusText()
    local available = self:IsApiAvailable()
    if not available then
        return L["API unavailable"]
    end

    if not self:IsHouseEditorActive() then
        return L["Enter Expert Decor mode"]
    end
    if not self:IsExpertDecorMode() then
        return L["Enter Expert Decor mode"]
    end

    if not self:IsDecorSelected() then
        return L["Select a decor item"]
    end

    local submode = self:GetSubmodeName(self:GetSubmode())
    if submode == "Rotate" then
        return L["Ready - Rotate"]
    elseif submode == "Scale" then
        return L["Ready - Scale"]
    end
    return L["Ready - Translate"]
end

function ns:GetActivePulseNames()
    local names = {}
    if not ns.Pulse then
        return names
    end

    for name, entry in pairs(self:GetIncrementMap()) do
        if ns.Pulse:IsActive(entry.enum) then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    return names
end

function ns:RefreshUI()
    if ns.UI and ns.UI.UpdateStatus then
        ns.UI:UpdateStatus()
    end
end

function ns:StopPulses(reason)
    if ns.Pulse then
        ns.Pulse:StopAll()
    end
    if reason then
        self:Debug("pulses stopped: " .. reason)
    end
end

function ns:CheckApiOnce()
    local available, reason = self:IsApiAvailable()
    if available or self.apiWarned then
        return
    end

    self.apiWarned = true
    self:Print(string.format(L["Housing precision API is unavailable (%s)."], tostring(reason)))
    self:Print(L["This addon requires retail Midnight 12.1.5 or newer with Housing enabled."])
end

function ns:PrintStatus()
    local available, reason = self:IsApiAvailable()
    if available then
        self:Print(L["API: available"])
    else
        self:Print(string.format(L["API: unavailable - %s"], tostring(reason)))
    end

    local editorActive = self:IsHouseEditorActive()
    if editorActive == nil then
        self:Print(L["House editor: unknown"])
    elseif editorActive then
        self:Print(L["House editor: active"])
    else
        self:Print(L["House editor: inactive"])
    end

    if self:IsExpertDecorMode() then
        self:Print(L["Expert Decor: yes"])
    else
        self:Print(L["Expert Decor: no"])
    end

    local selected = self:IsDecorSelected()
    if selected == nil then
        self:Print(L["Decor selected: unknown"])
    elseif selected then
        self:Print(L["Decor selected: yes"])
    else
        self:Print(L["Decor selected: no"])
    end

    self:Print(string.format(L["Precision submode: %s"], self:GetSubmodeName(self:GetSubmode())))
    self:Print(string.format(L["Default frames (steps): %s"], tostring(self.db and self.db.steps or 5)))

    local active = self:GetActivePulseNames()
    if #active == 0 then
        self:Print(L["Active pulses: none"])
    else
        self:Print(string.format(L["Active pulses: %s"], table.concat(active, ", ")))
    end
end

local HELP_LINES = {
    "/hn - toggle the window",
    "/hn show - show the window",
    "/hn hide - hide the window and stop pulses",
    "/hn pulse <type> [n] - pulse an increment type for n frames (default: steps)",
    "/hn stop - stop every increment type",
    "/hn status - print API, editor, selection, submode, steps, and active pulses",
    "/hn steps <n> - set the default frame count (clamped to 1..60)",
    "/hn commit - commit the selected decor movement",
    "/hn debug - toggle debug logging",
    "/hn reset - reset SavedVariables to defaults",
    "/hn help - print this help",
    "Types: left, right, forward, back, up, down, rotateleft, rotateright, scaleup, scaledown",
}

function ns:PrintHelp()
    for _, line in ipairs(HELP_LINES) do
        self:Print(L[line] or line)
    end
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function ns:HandlePulseCommand(rest)
    local typeName, framesText = rest:match("^(%S*)%s*(.-)$")
    typeName = string.lower(typeName or "")
    framesText = trim(framesText or "")

    if typeName == "" then
        self:Print(L["Usage: /hn pulse <type> [frames]"])
        return
    end

    local incrementType = self:GetIncrementType(typeName)
    if not incrementType then
        self:Print(string.format(L["Unknown increment type: %s"], typeName))
        return
    end

    local frames = self.db.steps
    if framesText ~= "" then
        frames = tonumber(framesText)
        if not frames then
            self:Print(L["Frames must be a number."])
            return
        end
    end

    ns.Pulse:Start(incrementType, frames)
    self:RefreshUI()
end

function ns:HandleCommitCommand()
    local available, reason = self:IsApiAvailable()
    if not available then
        self:Print(string.format(L["Cannot commit: %s"], tostring(reason)))
        return
    end
    if type(C_HousingExpertMode.CommitDecorMovement) ~= "function" then
        self:Print(L["CommitDecorMovement is unavailable."])
        return
    end

    local selected = self:IsDecorSelected()
    if selected == nil then
        self:Print(L["Could not read the decor selection."])
        return
    end
    if not selected then
        self:Print(L["Select a decor item first."])
        return
    end

    local ok, err = pcall(C_HousingExpertMode.CommitDecorMovement)
    if ok then
        self:Print(L["Movement committed."])
    else
        self:Print(string.format(L["Commit failed: %s"], tostring(err)))
    end
    self:RefreshUI()
end

function ns:HandleSlash(message)
    if not self.db then
        return
    end

    local input = trim(message or "")
    local command, rest = input:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = trim(rest or "")

    if command == "" then
        if ns.UI then
            ns.UI:Toggle()
        end
    elseif command == "show" then
        if ns.UI then
            ns.UI:Show()
        end
    elseif command == "hide" then
        if ns.UI then
            ns.UI:Hide()
        end
    elseif command == "pulse" then
        self:HandlePulseCommand(rest)
    elseif command == "stop" then
        self:StopPulses("slash command")
        self:Print("All pulses stopped.")
        self:RefreshUI()
    elseif command == "status" then
        self:PrintStatus()
    elseif command == "steps" then
        local value = tonumber(rest)
        if not value then
            self:Print(L["Usage: /hn steps <1-60>"])
            return
        end

        value = math.floor(value)
        if value < 1 then
            value = 1
        elseif value > 60 then
            value = 60
        end
        self.db.steps = value
        self:Print(string.format(L["Default pulse frames set to %s."], tostring(value)))
        if ns.UI and ns.UI.UpdateSteps then
            ns.UI:UpdateSteps()
        end
        self:RefreshUI()
    elseif command == "commit" then
        self:HandleCommitCommand()
    elseif command == "debug" then
        self.db.debug = not self.db.debug
        if self.db.debug then
            self:Print(L["Debug logging enabled."])
        else
            self:Print(L["Debug logging disabled."])
        end
    elseif command == "reset" then
        self:StopPulses("reset")
        self:ResetDB()
        self:Print(L["SavedVariables reset to defaults."])
        self:RefreshUI()
    elseif command == "help" then
        self:PrintHelp()
    else
        self:Print(string.format(L["Unknown command: %s"], command))
        self:PrintHelp()
    end
end

-- Global entry point used by Bindings.xml. WoW key bindings execute global
-- code, so keep this table small and route everything through the private ns.
_G.HousingNudge = _G.HousingNudge or {}
local HN = _G.HousingNudge

local function nudgeByKey(key)
    if not ns or not ns.Pulse then
        return
    end
    local incrementType = ns:GetIncrementType(key)
    if not incrementType then
        return
    end
    local steps = (ns.db and ns.db.steps) or 5
    ns.Pulse:Start(incrementType, steps)
    if ns.UI and ns.UI.UpdateStatus then
        ns.UI:UpdateStatus()
    end
end

HN.NudgeLeft = function()
    nudgeByKey("left")
end

HN.NudgeRight = function()
    nudgeByKey("right")
end

HN.NudgeForward = function()
    nudgeByKey("forward")
end

HN.NudgeBack = function()
    nudgeByKey("back")
end

HN.OpenKeyBindings = function()
    if KeyBindingFrame then
        ShowUIPanel(KeyBindingFrame)
    end
end

local eventFrame = CreateFrame("Frame")

local function registerEvent(event)
    -- A missing event on an older client should not prevent the addon from
    -- loading; capability detection reports the missing API surface instead.
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end

registerEvent("ADDON_LOADED")
registerEvent("PLAYER_ENTERING_WORLD")
registerEvent("PLAYER_LOGOUT")
registerEvent("HOUSE_EDITOR_MODE_CHANGED")
registerEvent("HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED")
registerEvent("HOUSING_DECOR_PRECISION_SUBMODE_CHANGED")
registerEvent("HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == ADDON_NAME then
            ns:InitDB()
            ns:CheckApiOnce()
            ns:RefreshUI()
        end
        return
    end

    if not ns.db then
        return
    end

    if event == "HOUSE_EDITOR_MODE_CHANGED" then
        ns.editorMode = ...
        ns:StopPulses("editor mode changed")
        ns:RefreshUI()
        return
    end

    if event == "HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED" then
        ns.hasSelectedTarget = ...
        ns:StopPulses("decor selection changed")
        ns:RefreshUI()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        ns.editorMode = nil
        ns.hasSelectedTarget = nil
        ns:StopPulses("player entering world")
        ns:RefreshUI()
        return
    end

    if event == "PLAYER_LOGOUT" then
        ns:StopPulses("player logout")
        return
    end

    if event == "HOUSING_DECOR_PRECISION_SUBMODE_CHANGED" then
        ns:RefreshUI()
        return
    end

    if event == "HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED" then
        ns:RefreshUI()
    end
end)

SLASH_HOUSINGNUDGE1 = "/hn"
SLASH_HOUSINGNUDGE2 = "/housingnudge"
SLASH_HOUSINGNUDGE3 = "/bdt"
SLASH_HOUSINGNUDGE4 = "/delvetool"
SlashCmdList["HOUSINGNUDGE"] = function(message)
    ns:HandleSlash(message)
end

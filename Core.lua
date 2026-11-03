local ADDON_NAME, ns = ...

-- Public-ish namespace shared by Core.lua, Pulse.lua, and UI.lua. The table is
-- private to this addon; nothing is added to _G.
ns.name = ADDON_NAME
ns.version = "0.1.0"
ns.PREFIX = "|cff33ff99Bears Decor Tool|r"

local aceLocale = LibStub and LibStub("AceLocale-3.0")
local L = aceLocale and aceLocale:GetLocale(ADDON_NAME)
if not L then
    L = setmetatable({}, { __index = function(_, key) return key end })
end
ns.L = L

local DB_DEFAULTS = {
    version = 1,
    steps = 3,
    stepLeftRight = 3,
    stepUpDown = 3,
    stepForwardBack = 3,
    debug = false,
    nudgingEnabled = true,
    minimap = {
        hide = false,
        minimapPos = 220,
    },
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

    local function sanitizeStep(value, fallback, maxVal)
        maxVal = maxVal or 10
        value = sanitizeNumber(value, fallback)
        value = math.floor(value)
        if value < 1 then
            value = 1
        elseif value > maxVal then
            value = maxVal
        end
        return value
    end

    db.steps = sanitizeStep(db.steps, DB_DEFAULTS.steps, 10)
    db.stepLeftRight = sanitizeStep(db.stepLeftRight, DB_DEFAULTS.stepLeftRight, 10)
    db.stepUpDown = sanitizeStep(db.stepUpDown, DB_DEFAULTS.stepUpDown, 10)
    db.stepForwardBack = sanitizeStep(db.stepForwardBack, DB_DEFAULTS.stepForwardBack, 10)

    if type(db.debug) ~= "boolean" then
        db.debug = DB_DEFAULTS.debug
    end

    if type(db.nudgingEnabled) ~= "boolean" then
        db.nudgingEnabled = DB_DEFAULTS.nudgingEnabled
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
    if type(BearsDecorToolDB) ~= "table" then
        BearsDecorToolDB = {}
    end
    mergeDefaults(BearsDecorToolDB, DB_DEFAULTS)
    self.db = BearsDecorToolDB
    self:SanitizeDB()
end

function ns:ResetDB()
    BearsDecorToolDB = {}
    mergeDefaults(BearsDecorToolDB, DB_DEFAULTS)
    self.db = BearsDecorToolDB
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

function ns:GetStepValue(key)
    if type(key) ~= "string" then
        key = ""
    end
    key = string.lower(key)
    local db = self.db
    if key == "left" or key == "right" then
        return (db and db.stepLeftRight) or DB_DEFAULTS.stepLeftRight
    elseif key == "up" or key == "down" then
        return (db and db.stepUpDown) or DB_DEFAULTS.stepUpDown
    elseif key == "forward" or key == "back" then
        return (db and db.stepForwardBack) or DB_DEFAULTS.stepForwardBack
    end
    return (db and db.steps) or DB_DEFAULTS.steps
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

    if self.editorMode ~= nil then
        return self.editorMode == modeEnum.ExpertDecor
    end

    -- Fallback evidence only. Expert Decor is the only mode with precision
    -- submodes or selectable decor instances.
    if not self:IsHouseEditorActive() then
        return false
    end
    if self:GetSubmode() ~= nil then
        return true
    end
    if self:IsDecorSelected() then
        return true
    end
    return false
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

-- Drag snap CVars that earlier builds wrote. Restoring them is done only by the
-- explicit /bdt resetsnap command.
local ROTATION_SNAP_CVAR = "housingExpertGizmos_Rotation_SnapDegrees"
local SNAP_ON_HOLD_CVAR = "housingExpertGizmos_SnapOnHold"
-- 1 = no snap unless SHIFT is held (Blizzard default, per ADT's "Default Snap
-- Enabled" tooltip). 0 = snap by default and SHIFT moves freely.
local SNAP_ON_HOLD_DEFAULT = 1

function ns:ResetDragSnapCVars()
    if not (C_CVar and C_CVar.SetCVar and C_CVar.GetCVar) then
        self:Print("Cannot reset drag snap: C_CVar is unavailable.")
        return false
    end

    local degreesDefault = C_CVar.GetCVarDefault and C_CVar.GetCVarDefault(ROTATION_SNAP_CVAR)
    local okHold, holdSet = pcall(C_CVar.SetCVar, SNAP_ON_HOLD_CVAR, tostring(SNAP_ON_HOLD_DEFAULT))
    local okDeg, degSet = false, false
    if degreesDefault ~= nil then
        okDeg, degSet = pcall(C_CVar.SetCVar, ROTATION_SNAP_CVAR, tostring(degreesDefault))
    end

    local holdOk = okHold and holdSet == true
    local degOk = okDeg and degSet == true
    self:Debug(string.format("reset snapOnHold=%s: %s; snapDegrees=%s: %s",
        tostring(SNAP_ON_HOLD_DEFAULT), tostring(holdOk),
        tostring(degreesDefault), tostring(degOk)))

    -- Print what the game now reports, so a mismatch is visible.
    self:Print(string.format("SnapOnHold = %s, Rotation snap degrees = %s",
        tostring(C_CVar.GetCVar(SNAP_ON_HOLD_CVAR)), tostring(C_CVar.GetCVar(ROTATION_SNAP_CVAR))))
    if holdOk and degOk then
        self:Print("Drag snap settings restored.")
    else
        self:Print("Could not restore every drag snap setting. Check /bdt debug output.")
    end
    return holdOk and degOk
end

function ns:IsNudgingEnabled()
    return not self.db or self.db.nudgingEnabled ~= false
end


function ns:SetNudgingEnabled(enabled)
    if not self.db then
        return
    end
    self.db.nudgingEnabled = enabled and true or false
    if not self.db.nudgingEnabled then
        self:StopPulses("nudging off")
    end
    self:UpdateOverrideBindings()
    self:Print(self.db.nudgingEnabled and L["Nudging on."] or L["Nudging off."])
    self:RefreshUI()
end

function ns:GetStatusText()
    local available = self:IsApiAvailable()
    if not available then
        return L["API unavailable"]
    end

    if not self:IsNudgingEnabled() then
        return L["Nudging is off. Use /bdt on."]
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

    self:Print(string.format(L["Nudging: %s"], self:IsNudgingEnabled() and "on" or "off"))

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
    self:Print(string.format(L["Default frames (steps): %s"], tostring(self.db and self.db.steps or 3)))

    local active = self:GetActivePulseNames()
    if #active == 0 then
        self:Print(L["Active pulses: none"])
    else
        self:Print(string.format(L["Active pulses: %s"], table.concat(active, ", ")))
    end
end

local HELP_LINES = {
    "/bdt - toggle the window",
    "/bdt show - show the window",
    "/bdt hide - hide the window and stop pulses",
    "/bdt pulse <type> [n] - pulse an increment type for n frames (default: steps)",
    "/bdt stop - stop every increment type",
    "/bdt status - print API, editor, selection, submode, steps, and active pulses",
    "/bdt on - turn nudging on",
    "/bdt off - turn nudging off and stop pulses",
    "/bdt resetsnap - restore the game's default drag snap settings",
    "/bdt steps <n> - set the default frame count (clamped to 1..10)",
    "/bdt commit - commit the selected decor movement",
    "/bdt debug - toggle debug logging",
    "/bdt reset - reset SavedVariables to defaults",
    "/bdt help - print this help",
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
        self:Print(L["Usage: /bdt pulse <type> [frames]"])
        return
    end

    local incrementType = self:GetIncrementType(typeName)
    if not incrementType then
        self:Print(string.format(L["Unknown increment type: %s"], typeName))
        return
    end

    local frames = self:GetStepValue(typeName)
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
            self:Print(L["Usage: /bdt steps <1-10>"])
            return
        end

        value = math.floor(value)
        if value < 1 then
            value = 1
        elseif value > 10 then
            value = 10
        end
        self.db.steps = value
        self:Print(string.format(L["Default pulse frames set to %s."], tostring(value)))
        if ns.UI and ns.UI.UpdateSteps then
            ns.UI:UpdateSteps()
        end
        self:RefreshUI()
    elseif command == "resetsnap" then
        self:ResetDragSnapCVars()
    elseif command == "on" then
        self:SetNudgingEnabled(true)
    elseif command == "off" then
        self:SetNudgingEnabled(false)
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

local function resolveNudgeKey(key)
    if type(key) ~= "string" then
        return key
    end
    key = string.lower(key)
    local submode = ns:GetSubmodeName(ns:GetSubmode())
    if submode == "Rotate" then
        if key == "left" then
            return "rotateleft"
        elseif key == "right" then
            return "rotateright"
        elseif key == "forward" then
            return "rotateright"
        elseif key == "back" then
            return "rotateleft"
        end
    elseif submode == "Scale" then
        if key == "left" then
            return "scaledown"
        elseif key == "right" then
            return "scaleup"
        elseif key == "forward" then
            return "scaleup"
        elseif key == "back" then
            return "scaledown"
        end
    end
    return key
end

-- Resolves a nudge key (left, forward, ...) to the increment type for the
-- current submode. Returns nil when the submode has no matching increment.
function ns:GetNudgeIncrementType(key)
    local resolved = resolveNudgeKey(key)
    return self:GetIncrementType(resolved), self:GetStepValue(resolved)
end

-- Frame pulse for one key press, using the step value for that direction.
local function nudgeByKey(key)
    if not ns or not ns.Pulse then
        return
    end
    local resolved = resolveNudgeKey(key)
    local incrementType = ns:GetIncrementType(resolved)
    if not incrementType then
        return
    end
    local steps = ns:GetStepValue(resolved)
    ns.Pulse:Start(incrementType, steps)
    if ns.UI and ns.UI.UpdateStatus then
        ns.UI:UpdateStatus()
    end
end
ns.NudgeByKey = nudgeByKey

local eventFrame = CreateFrame("Frame")

-- Temporary override frame used to route Expert Decor nudge keys through the
-- addon's step values without permanently changing the player's keybindings.
local overrideFrame = CreateFrame("Frame", "BearsDecorToolOverrideFrame")

-- Arrow and Page keys route to the hold-aware buttons in Hold.lua. Those buttons
-- report key-down and key-up, which hold-to-move needs.
local OVERRIDE_KEYS = {
    { "LEFT", "left" },
    { "RIGHT", "right" },
    { "UP", "forward" },
    { "DOWN", "back" },
    { "PAGEUP", "up" },
    { "PAGEDOWN", "down" },
}

function ns:UpdateOverrideBindings()
    if type(ClearOverrideBindings) ~= "function" then
        return
    end

    if self:IsExpertDecorMode() and self:IsNudgingEnabled() and ns.Hold then
        if type(SetOverrideBindingClick) ~= "function" then
            return
        end
        ClearOverrideBindings(overrideFrame)
        for _, entry in ipairs(OVERRIDE_KEYS) do
            local buttonName = ns.Hold.GetButtonName(entry[2])
            if buttonName then
                pcall(SetOverrideBindingClick, overrideFrame, true, entry[1], buttonName, "LeftButton")
            end
        end
    else
        pcall(ClearOverrideBindings, overrideFrame)
    end
end

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
            ns:UpdateOverrideBindings()
            if ns.Minimap then
                ns.Minimap:Create()
            end

            -- Do not modify the player's keybindings. Step values are applied to
            -- the addon's optional bindings only when the user assigns them.

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
        ns:UpdateOverrideBindings()
        ns:RefreshUI()
        return
    end

    if event == "HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED" then
        local hasSelectedTarget = ...
        ns.hasSelectedTarget = hasSelectedTarget
        if hasSelectedTarget and Enum and Enum.HouseEditorMode then
            ns.editorMode = Enum.HouseEditorMode.ExpertDecor
        end
        ns:StopPulses("decor selection changed")
        ns:UpdateOverrideBindings()
        ns:RefreshUI()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        ns.editorMode = nil
        ns.hasSelectedTarget = nil
        ns:StopPulses("player entering world")
        ns:UpdateOverrideBindings()
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

SLASH_BDT1 = "/bdt"
SlashCmdList["BDT"] = function(message)
    ns:HandleSlash(message)
end

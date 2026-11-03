local _, ns = ...

ns.Pulse = ns.Pulse or {}
local Pulse = ns.Pulse

local L = ns.L
if not L then
    L = setmetatable({}, { __index = function(_, key) return key end })
end

-- ACTIVE_FRAME_BIAS keeps an increment active for one extra OnUpdate tick.
-- This guarantees the C-side housing update sees at least one active frame
-- after the initial call, but the exact displacement is NOT guaranteed. The
-- step count must be calibrated in-game at different frame rates.
local ACTIVE_FRAME_BIAS = 1

-- Safety cap: no pulse may remain active longer than this, even if the driver
-- frame errors or stops receiving OnUpdate.
local MAX_ACTIVE_SECONDS = 3
local MAX_FRAMES = 60

Pulse.activeType = nil
Pulse.framesLeft = 0
Pulse.startedAt = 0
Pulse.token = 0
Pulse.driver = nil
Pulse.failurePrinted = false

local function setIncrementActive(incrementType, active)
    if type(C_HousingExpertMode) ~= "table" then
        return false
    end
    if type(C_HousingExpertMode.SetPrecisionIncrementingActive) ~= "function" then
        return false
    end

    local ok, err = pcall(C_HousingExpertMode.SetPrecisionIncrementingActive, incrementType, active)
    if not ok then
        if not Pulse.failurePrinted then
            Pulse.failurePrinted = true
            ns:Print(string.format(L["Precision API call failed: %s"], tostring(err)))
        end
        return false
    end
    return true
end

local function setSubmode(submode)
    if type(C_HousingExpertMode) ~= "table" then
        return false
    end
    if type(C_HousingExpertMode.SetPrecisionSubmode) ~= "function" then
        ns:Print(L["Precision submode API is unavailable."])
        return false
    end

    local ok, err = pcall(C_HousingExpertMode.SetPrecisionSubmode, submode)
    if not ok then
        if not Pulse.failurePrinted then
            Pulse.failurePrinted = true
            ns:Print(string.format(L["Could not set precision submode: %s"], tostring(err)))
        end
        return false
    end
    return true
end

local function getDriver()
    if Pulse.driver then
        return Pulse.driver
    end

    local driver = CreateFrame("Frame")
    driver:Hide()
    driver:SetScript("OnUpdate", function()
        Pulse:OnUpdate()
    end)
    Pulse.driver = driver
    return driver
end

function Pulse:StopDriver()
    if self.driver then
        self.driver:Hide()
    end
end

function Pulse:OnUpdate()
    local incrementType = self.activeType
    if incrementType == nil then
        self:StopDriver()
        return
    end

    if (GetTime() - self.startedAt) >= MAX_ACTIVE_SECONDS then
        self:Stop(incrementType)
        return
    end

    self.framesLeft = self.framesLeft - 1
    if self.framesLeft <= 0 then
        self:Stop(incrementType)
    end
end

function Pulse:Start(incrementType, frames)
    if incrementType == nil then
        ns:Print(L["Cannot pulse: unknown increment type."])
        return false
    end

    local canPulse, reason = ns:CanPulse()
    if not canPulse then
        self:StopAll()
        ns:Print(reason)
        return false
    end

    frames = tonumber(frames) or (ns.db and ns.db.steps) or 1
    frames = math.floor(frames)
    if frames < 1 then
        frames = 1
    elseif frames > MAX_FRAMES then
        frames = MAX_FRAMES
    end

    -- Only one increment type may be active at a time. Multi-axis or diagonal
    -- movement is a future feature; for now, starting one pulse clears the rest.
    self:StopAll()
    self.failurePrinted = false

    local requiredSubmode = ns:GetSubmodeForIncrement(incrementType)
    if requiredSubmode == nil then
        ns:Print(L["Could not resolve the precision submode for this increment."])
        return false
    end

    if ns:GetSubmode() ~= requiredSubmode then
        if not setSubmode(requiredSubmode) then
            return false
        end
        -- TODO: if SetPrecisionSubmode proves asynchronous, defer the
        -- activation below by one frame and re-check the current submode.
    end

    if not setIncrementActive(incrementType, true) then
        return false
    end

    self.token = self.token + 1
    local token = self.token
    self.activeType = incrementType
    self.framesLeft = frames + ACTIVE_FRAME_BIAS
    self.startedAt = GetTime()

    -- Schedule the independent backstop before showing the driver, so a driver
    -- error cannot leave the increment active. The token check makes stale
    -- timers harmless after any stop, restart, or panic StopAll.
    local timerOk = pcall(function()
        C_Timer.After(MAX_ACTIVE_SECONDS, function()
            if Pulse.token == token and Pulse.activeType == incrementType then
                Pulse:Stop(incrementType)
            end
        end)
    end)
    if not timerOk then
        self:Stop(incrementType)
        ns:Print(L["Could not schedule the pulse safety timer; pulse stopped."])
        return false
    end

    local driverOk = pcall(function()
        getDriver():Show()
    end)
    if not driverOk then
        self:Stop(incrementType)
        ns:Print(L["Pulse driver failed; pulse stopped."])
        return false
    end

    ns:Debug(string.format(
        "pulse start: type=%s frames=%d bias=%d",
        ns:GetIncrementName(incrementType),
        frames,
        ACTIVE_FRAME_BIAS
    ))

    return true
end

function Pulse:Stop(incrementType)
    if incrementType == nil then
        return false
    end

    local wasActive = self.activeType == incrementType
    if wasActive then
        self.activeType = nil
        self.framesLeft = 0
        self.token = self.token + 1
        self:StopDriver()
    end

    local ok = setIncrementActive(incrementType, false)

    if wasActive then
        ns:Debug("pulse stop: type=" .. ns:GetIncrementName(incrementType))
    end

    return ok
end

function Pulse:StopAll()
    local wasActive = self.activeType ~= nil

    self.activeType = nil
    self.framesLeft = 0
    self.token = self.token + 1
    self:StopDriver()

    -- Panic path: clear every known increment type, regardless of internal
    -- state. This is intentionally more aggressive than stopping one type.
    for _, entry in pairs(ns:GetIncrementMap()) do
        setIncrementActive(entry.enum, false)
    end

    if wasActive then
        ns:Debug("pulse stop all")
    end
end

function Pulse:IsActive(incrementType)
    return self.activeType ~= nil and self.activeType == incrementType
end

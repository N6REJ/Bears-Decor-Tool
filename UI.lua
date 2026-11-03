local _, ns = ...

ns.UI = ns.UI or {}
local UI = ns.UI

local L = ns.L
if not L then
    L = setmetatable({}, { __index = function(_, key) return key end })
end

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

local NUDGE_ROWS = {
    { { "Forward", "forward" }, { "Back", "back" } },
    { { "Left", "left" }, { "Right", "right" } },
    { { "Up", "up" }, { "Down", "down" } },
    { { "Rotate Left", "rotateleft" }, { "Rotate Right", "rotateright" } },
    { { "Scale Down", "scaledown" }, { "Scale Up", "scaleup" } },
}

local function createButton(parent, text, width, height, point, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetPoint(point, parent, point, x, y)
    button:SetText(text)
    return button
end

local function addNudgeButton(parent, text, key, point, x, y)
    local button = createButton(parent, text, 112, 24, point, x, y)
    button:SetScript("OnClick", function()
        ns.UI:Nudge(key)
    end)
    return button
end

local function createSlider(parent, width, minVal, maxVal, point, x, y)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetSize(width, 16)
    slider:SetPoint(point, parent, point, x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    if slider.Low then
        slider.Low:SetText(tostring(minVal))
    end
    if slider.High then
        slider.High:SetText(tostring(maxVal))
    end
    return slider
end

local function bindStepSlider(slider, dbKey, valueText)
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor((tonumber(value) or 1) + 0.5)
        if value < 1 then
            value = 1
        elseif value > 60 then
            value = 60
        end
        if ns.db then
            ns.db[dbKey] = value
            ns:SanitizeDB()
        end
        if valueText then
            valueText:SetText(tostring(value))
        end
        if ns.UI and ns.UI.UpdateStatus then
            ns.UI:UpdateStatus()
        end
    end)
    return slider
end

function UI:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, WorldFrame, "BackdropTemplate")
    self.frame = frame
    frame:Hide()

    frame:SetSize(260, 340)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        ns.UI:SavePosition()
    end)
    frame:SetScript("OnShow", function()
        ns.UI:UpdateStatus()
    end)
    frame:SetScript("OnHide", function()
        ns:StopPulses("UI hidden")
        ns.UI:UpdateStatus()
    end)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -12)
    title:SetText(L["Bears Decor Tool"])

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        ns.UI:Hide()
    end)

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOP", frame, "TOP", 0, -38)
    status:SetWidth(236)
    status:SetJustifyH("CENTER")
    status:SetText(L["API unavailable"])
    self.status = status

    -- Per-category step sliders. Each slider edits the frame count used for the
    -- corresponding nudge direction; the value is persisted in SavedVariables and
    -- applied to the already-assigned keybinds and mouse wheel movement.
    local fieldStartY = -62
    local fieldSpacing = 46

    local function makeStepSlider(labelText, dbKey, index)
        local y = fieldStartY - (index * fieldSpacing)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, y + 12)
        label:SetText(labelText)

        local valueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valueText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, y + 12)
        valueText:SetText("5")

        local slider = createSlider(frame, 220, 1, 60, "TOP", 0, y - 10)
        bindStepSlider(slider, dbKey, valueText)
        return slider, valueText
    end

    self.stepSliderLeftRight, self.stepValueLeftRight = makeStepSlider(L["Left/Right steps:"], "stepLeftRight", 0)
    self.stepSliderUpDown, self.stepValueUpDown = makeStepSlider(L["Up/Down steps:"], "stepUpDown", 1)
    self.stepSliderWheel, self.stepValueWheel = makeStepSlider(L["Wheel steps:"], "stepWheel", 2)
    self.stepSliderOther, self.stepValueOther = makeStepSlider(L["Other steps:"], "steps", 3)

    -- Nudge buttons are intentionally omitted: step values affect the already
    -- assigned keybinds and mouse wheel movement.

    -- No action buttons: step sliders affect the already-assigned keybinds and
    -- mouse wheel movement. Use /hn stop and /bdt commit when needed.

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
    hint:SetText(L["Wheel nudges forward/back. Relative nudges only."])

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        if delta and delta > 0 then
            ns.UI:Nudge("forward")
        elseif delta and delta < 0 then
            ns.UI:Nudge("back")
        end
    end)

    self:ApplyPosition()
    self:UpdateStatus()
    self:UpdateSteps()

    return frame
end

function UI:GetFrame()
    if self.frame then
        return self.frame
    end
    return self:Create()
end

function UI:Toggle()
    local frame = self:GetFrame()
    if frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function UI:Show()
    local frame = self:GetFrame()
    frame:SetAlpha(1)
    frame:Show()
    self:UpdateStatus()
    self:UpdateSteps()
    ns:Print("Bears_Decor_Tool window shown (shown=" .. tostring(frame:IsShown()) .. ", visible=" .. tostring(frame:IsVisible()) .. ", alpha=" .. tostring(frame:GetAlpha()) .. ", parent=" .. tostring(frame:GetParent() and frame:GetParent():GetName() or "nil") .. ").")
end

function UI:Hide()
    ns:StopPulses("UI hidden")
    if self.frame then
        self.frame:Hide()
    end
    self:UpdateStatus()
end

function UI:UpdateStatus()
    if not self.frame or not self.status then
        return
    end
    self.status:SetText(ns:GetStatusText())
end

function UI:UpdateSteps()
    if not self.frame then
        return
    end
    local pairs = {
        { self.stepSliderLeftRight, self.stepValueLeftRight, "stepLeftRight" },
        { self.stepSliderUpDown, self.stepValueUpDown, "stepUpDown" },
        { self.stepSliderWheel, self.stepValueWheel, "stepWheel" },
        { self.stepSliderOther, self.stepValueOther, "steps" },
    }
    for _, entry in ipairs(pairs) do
        local slider, valueText, dbKey = entry[1], entry[2], entry[3]
        if slider then
            local value = (ns.db and ns.db[dbKey]) or 5
            slider:SetValue(value)
            if valueText then
                valueText:SetText(tostring(value))
            end
        end
    end
end

function UI:Nudge(key)
    local incrementType = ns:GetIncrementType(key)
    if not incrementType then
        ns:Print(string.format(L["Increment type unavailable: %s"], tostring(key)))
        self:UpdateStatus()
        return
    end

    local steps = ns:GetStepValue(key)
    ns.Pulse:Start(incrementType, steps)
    self:UpdateStatus()
end

function UI:Commit()
    local available, reason = ns:IsApiAvailable()
    if not available then
        ns:Print(string.format(L["Cannot commit: %s"], tostring(reason)))
        return
    end
    if type(C_HousingExpertMode.CommitDecorMovement) ~= "function" then
        ns:Print(L["CommitDecorMovement is unavailable."])
        return
    end

    local selected = ns:IsDecorSelected()
    if selected == nil then
        ns:Print(L["Could not read the decor selection."])
        return
    end
    if not selected then
        ns:Print(L["Select a decor item first."])
        return
    end

    local ok, err = pcall(C_HousingExpertMode.CommitDecorMovement)
    if ok then
        ns:Print(L["Movement committed."])
    else
        ns:Print(string.format(L["Commit failed: %s"], tostring(err)))
    end
    self:UpdateStatus()
end

function UI:SavePosition()
    if not self.frame or not ns.db or not ns.db.frame then
        return
    end

    local point, _, relPoint, x, y = self.frame:GetPoint(1)
    if not point then
        return
    end

    ns.db.frame.point = point
    ns.db.frame.relPoint = relPoint or "CENTER"
    ns.db.frame.x = x or 0
    ns.db.frame.y = y or 0
end

function UI:ApplyPosition()
    if not self.frame or not ns.db or not ns.db.frame then
        return
    end

    local saved = ns.db.frame
    local point = saved.point
    local relPoint = saved.relPoint

    if not VALID_POINTS[point] then
        point = "CENTER"
    end
    if not VALID_POINTS[relPoint] then
        relPoint = "CENTER"
    end

    local x = tonumber(saved.x) or 0
    local y = tonumber(saved.y) or 0

    self.frame:ClearAllPoints()
    self.frame:SetPoint(point, WorldFrame, relPoint, x, y)
end

function UI:ResetPosition()
    if not ns.db or not ns.db.frame then
        return
    end

    ns.db.frame.point = "CENTER"
    ns.db.frame.relPoint = "CENTER"
    ns.db.frame.x = 0
    ns.db.frame.y = 0

    self:ApplyPosition()
end

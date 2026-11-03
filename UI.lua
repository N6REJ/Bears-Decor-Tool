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

local function createEditBox(parent, width, height, point, x, y)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, height)
    eb:SetPoint(point, parent, point, x, y)
    eb:SetAutoFocus(false)
    eb:SetNumeric(true)
    eb:SetMaxLetters(3)
    eb:SetTextInsets(4, 4, 0, 0)
    return eb
end

local function bindStepField(editBox, dbKey)
    local function commit(self)
        local value = tonumber(self:GetText())
        if not value then
            value = (ns.db and ns.db[dbKey]) or 5
        end
        value = math.floor(value)
        if value < 1 then
            value = 1
        elseif value > 60 then
            value = 60
        end
        if ns.db then
            ns.db[dbKey] = value
            ns:SanitizeDB()
        end
        self:SetText(tostring(value))
        self:ClearFocus()
        if ns.UI and ns.UI.UpdateStatus then
            ns.UI:UpdateStatus()
        end
    end
    editBox:SetScript("OnEnterPressed", commit)
    editBox:SetScript("OnEditFocusLost", commit)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return editBox
end

function UI:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", nil, WorldFrame, "BackdropTemplate")
    self.frame = frame
    frame:Hide()

    frame:SetSize(260, 700)
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

    -- Per-category step fields. Each field edits the frame count used for the
    -- corresponding nudge direction; the value is persisted in SavedVariables.
    local fieldStartY = -58
    local fieldSpacing = 20

    local function makeStepField(labelText, dbKey, index)
        local y = fieldStartY - (index * fieldSpacing)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, y + 2)
        label:SetText(labelText)

        local eb = createEditBox(frame, 46, 20, "TOPRIGHT", -12, y - 2)
        bindStepField(eb, dbKey)
        return eb
    end

    self.stepFieldLeftRight = makeStepField(L["Left/Right steps:"], "stepLeftRight", 0)
    self.stepFieldUpDown = makeStepField(L["Up/Down steps:"], "stepUpDown", 1)
    self.stepFieldWheel = makeStepField(L["Wheel steps:"], "stepWheel", 2)
    self.stepFieldOther = makeStepField(L["Other steps:"], "steps", 3)

    local startY = -136
    local rowHeight = 30
    for rowIndex, row in ipairs(NUDGE_ROWS) do
        local y = startY - ((rowIndex - 1) * rowHeight)
        local left = row[1]
        local right = row[2]

        addNudgeButton(frame, L[left[1]], left[2], "TOPLEFT", 12, y)
        addNudgeButton(frame, L[right[1]], right[2], "TOPRIGHT", -12, y)
    end

    local stop = createButton(frame, L["Stop"], 236, 26, "TOP", 0, -276)
    stop:SetScript("OnClick", function()
        ns:StopPulses("Stop button")
        ns.UI:UpdateStatus()
    end)

    local commit = createButton(frame, L["Commit"], 236, 26, "TOP", 0, -310)
    commit:SetScript("OnClick", function()
        ns.UI:Commit()
    end)

    local keys = createButton(frame, L["Keybinds"], 236, 22, "TOP", 0, -344)
    keys:SetScript("OnClick", function()
        if _G.Bears_Decor_Tool and _G.Bears_Decor_Tool.OpenKeyBindings then
            _G.Bears_Decor_Tool.OpenKeyBindings()
        elseif KeyBindingFrame then
            ShowUIPanel(KeyBindingFrame)
        end
    end)

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
    local function setField(field, dbKey)
        if field then
            field:SetText(tostring((ns.db and ns.db[dbKey]) or 5))
        end
    end
    setField(self.stepFieldLeftRight, "stepLeftRight")
    setField(self.stepFieldUpDown, "stepUpDown")
    setField(self.stepFieldWheel, "stepWheel")
    setField(self.stepFieldOther, "steps")
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

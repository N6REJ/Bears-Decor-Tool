local _, ns = ...

ns.Minimap = ns.Minimap or {}
local MB = ns.Minimap

local L = ns.L
if not L then
    L = setmetatable({}, { __index = function(_, key) return key end })
end

-- The icon is parented to UIParent and anchored to Minimap. Blizzard's Minimap
-- frame itself is not changed. Position is stored as an angle in degrees.
local ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Map02"
local BORDER_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBorder"
local HIGHLIGHT_TEXTURE = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"

local button

-- math.atan2 is not in Lua 5.1, so compute the quadrant by hand.
local function atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 then
        return math.atan(y / x) - math.pi
    elseif y > 0 then
        return math.pi / 2
    elseif y < 0 then
        return -math.pi / 2
    end
    return 0
end

local function radius()
    local width = Minimap and Minimap:GetWidth() or 140
    return width / 2 + 5
end

local function place(angle)
    if not button or not Minimap then
        return
    end
    local rad = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius(), math.sin(rad) * radius())
end

local function angleFromCursor()
    local cx, cy = Minimap:GetCenter()
    local scale = UIParent:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    mx, my = mx / scale, my / scale
    return math.deg(atan2(my - cy, mx - cx))
end

local function updateDrag()
    if not ns.db or not Minimap then
        return
    end
    local angle = angleFromCursor() % 360
    ns.db.minimapAngle = angle
    place(angle)
end

function MB:Create()
    if button then
        return button
    end
    if not Minimap or not CreateFrame then
        return nil
    end

    button = CreateFrame("Button", "BearsDecorToolMinimapButton", UIParent)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON_TEXTURE)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture(BORDER_TEXTURE)

    button:SetHighlightTexture(HIGHLIGHT_TEXTURE)

    button:SetScript("OnClick", function()
        if ns.UI then
            ns.UI:Toggle()
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", updateDrag)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Bears_Decor_Tool"])
        GameTooltip:AddLine(L["Click to open or close the options."], 1, 1, 1)
        GameTooltip:AddLine(L["Drag to move this icon around the minimap."], 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    place((ns.db and ns.db.minimapAngle) or 220)
    button:Show()
    return button
end

local ADDON_NAME, ns = ...

ns.Minimap = ns.Minimap or {}
local MB = ns.Minimap

local L = ns.L
if not L then
    L = setmetatable({}, { __index = function(_, key) return key end })
end

-- The minimap button is created by LibDBIcon-1.0 from a LibDataBroker launcher.
-- LibDBIcon handles placement, layering, and dragging around the minimap. Its
-- saved state (angle and hidden flag) lives in ns.db.minimap.
local ICON_TEXTURE = "Interface\\AddOns\\" .. ADDON_NAME .. "\\nudge.tga"

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

local launcher
local registered = false

function MB:Create()
    if registered then
        return launcher
    end
    if not (LDB and DBIcon and ns.db) then
        return nil
    end

    launcher = LDB:NewDataObject("BearsDecorTool", {
        type = "launcher",
        text = L["Bears Decor Tool"],
        icon = ICON_TEXTURE,
        OnClick = function(_, button)
            if button == "LeftButton" and ns.UI then
                ns.UI:Toggle()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(L["Bears Decor Tool"])
            tooltip:AddLine(L["Click to open or close the options."], 1, 1, 1)
            tooltip:AddLine(L["Drag to move this icon around the minimap."], 1, 1, 1)
        end,
    })

    DBIcon:Register(ADDON_NAME, launcher, ns.db.minimap)
    registered = true
    return launcher
end

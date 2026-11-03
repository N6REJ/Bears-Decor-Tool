local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local ADDON_TITLE = L["Bears Delve Tool"]
local ADDON_ICON = "Interface\\Icons\\inv_misc_map_01"

local addon = AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
addonTable.addon = addon

local defaults = {
    profile = {
        debug = false,
        showMinimapButton = true,
        minimap = {
            hide = false,
        },
    },
}

local function SyncMinimapDefaults(profile)
    profile.minimap = profile.minimap or {}
    profile.minimap.hide = not profile.showMinimapButton
end

function addon:OnInitialize()
    self.db = AceDB:New("BearsDelveToolDB", defaults, true)
    SyncMinimapDefaults(self.db.profile)

    self:RegisterChatCommand("bdt", "SlashCommand")
    self:RegisterChatCommand("delvetool", "SlashCommand")

    addonTable.RegisterOptions(self)

    self:Print(L["Loaded. Type /bdt to open options."])
end

function addon:OnEnable()
    self:CreateMinimapButton()
end

function addon:CreateMinimapButton()
    if self.minimapButton then
        return
    end

    local LDB = LibStub("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDB or not LibDBIcon then
        return
    end

    self.minimapButton = LDB:NewDataObject(addonName, {
        type = "launcher",
        icon = ADDON_ICON,
        OnClick = function(_, button)
            if button == "LeftButton" then
                addon:OpenOptions()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(ADDON_TITLE)
            tooltip:AddLine(L["Click to open options."], 1, 1, 1)
        end,
    })

    LibDBIcon:Register(addonName, self.minimapButton, self.db.profile.minimap)
end

function addon:RefreshMinimapButton()
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LibDBIcon or not self.minimapButton then
        return
    end

    SyncMinimapDefaults(self.db.profile)
    LibDBIcon:Refresh(addonName, self.db.profile.minimap)
end

function addon:ResetSettings()
    self.db:ResetProfile()
    SyncMinimapDefaults(self.db.profile)
    self:RefreshMinimapButton()
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    self:Print(L["Settings reset to defaults."])
end

function addon:SlashCommand(input)
    local command = (input or ""):match("^%s*(.-)%s*$"):lower()
    if command == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print(self.db.profile.debug and L["Debug logging enabled."] or L["Debug logging disabled."])
        LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
        return
    end

    if command == "reset" then
        self:ResetSettings()
        return
    end

    self:OpenOptions()
end

function addon:DebugPrint(...)
    if self.db.profile.debug then
        self:Print(...)
    end
end

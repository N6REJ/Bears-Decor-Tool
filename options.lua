local addonName, addonTable = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addonTable.RegisterOptions(addon)
    local options = {
        type = "group",
        name = L["Bears Delve Tool"],
        args = {
            general = {
                type = "group",
                name = L["General"],
                inline = true,
                order = 1,
                args = {
                    showMinimapButton = {
                        type = "toggle",
                        order = 1,
                        width = "full",
                        name = L["Show minimap button"],
                        desc = L["Show or hide the minimap button."],
                        get = function()
                            return addon.db.profile.showMinimapButton
                        end,
                        set = function(_, value)
                            addon.db.profile.showMinimapButton = value
                            addon:RefreshMinimapButton()
                        end,
                    },
                    debug = {
                        type = "toggle",
                        order = 2,
                        width = "full",
                        name = L["Enable debug messages"],
                        desc = L["Print extra messages to chat for troubleshooting."],
                        get = function()
                            return addon.db.profile.debug
                        end,
                        set = function(_, value)
                            addon.db.profile.debug = value
                        end,
                    },
                },
            },
            commands = {
                type = "group",
                name = L["Commands"],
                inline = true,
                order = 2,
                args = {
                    help = {
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                        name = L["Slash commands: /bdt or /delvetool to open options. /bdt debug toggles debug messages. /bdt reset restores defaults."],
                    },
                },
            },
            reset = {
                type = "execute",
                order = 3,
                width = "normal",
                name = L["Reset settings"],
                desc = L["Restore all options to their default values."],
                func = function()
                    addon:ResetSettings()
                end,
            },
        },
    }

    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    AceConfigRegistry:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, L["Bears Delve Tool"])

    addon.OpenOptions = function()
        AceConfigDialog:Open(addonName)
    end
end

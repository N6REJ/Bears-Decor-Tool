local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "deDE")
if not L then return end

L["Left/Right (frames per press):"] = "Links/Rechts (Frames pro Druck):"
L["Up/Down (frames per press):"] = "Hoch/Runter (Frames pro Druck):"
L["Forward/Back (frames per press):"] = "Vor/Zurück (Frames pro Druck):"
L["Drag snap (degrees):"] = "Fang-Rasterung (Grad):"
L["Rotate/Scale (frames per press):"] = "Drehen/Skalieren (Frames pro Druck):"
L["Usage: /bdt steps <1-10>"] = "Verwendung: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - Standardanzahl Frames setzen (Standard 5, begrenzt auf 1..10)"

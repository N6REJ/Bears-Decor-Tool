local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "frFR")
if not L then return end

L["Left/Right (frames per press):"] = "Gauche/Droite (images par appui) :"
L["Up/Down (frames per press):"] = "Haut/Bas (images par appui) :"
L["Forward/Back (frames per press):"] = "Avant/Arrière (images par appui) :"
L["Drag snap (degrees):"] = "Magnétisme de glissement (degrés) :"
L["Rotate/Scale (frames per press):"] = "Rotation/Échelle (images par appui) :"
L["Usage: /bdt steps <1-10>"] = "Utilisation : /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - définir le nombre de frames par défaut (défaut 5, limité à 1..10)"

local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "itIT")
if not L then return end

L["Left/Right (frames per press):"] = "Sinistra/Destra (frame per pressione):"
L["Up/Down (frames per press):"] = "Su/Giù (frame per pressione):"
L["Forward/Back (frames per press):"] = "Avanti/Indietro (frame per pressione):"
L["Drag snap (degrees):"] = "Scatto trascinamento (gradi):"
L["Rotate/Scale (frames per press):"] = "Rotazione/Scala (frame per pressione):"
L["Usage: /bdt steps <1-10>"] = "Uso: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - imposta il numero di frame predefinito (predefinito 5, limitato a 1..10)"

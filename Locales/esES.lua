local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "esES")
if not L then return end

L["Left/Right (frames per press):"] = "Izquierda/Derecha (frames por pulsación):"
L["Up/Down (frames per press):"] = "Arriba/Abajo (frames por pulsación):"
L["Forward/Back (frames per press):"] = "Adelante/Atrás (frames por pulsación):"
L["Drag snap (degrees):"] = "Ajuste al arrastrar (grados):"
L["Rotate/Scale (frames per press):"] = "Rotar/Escalar (frames por pulsación):"
L["Usage: /bdt steps <1-10>"] = "Uso: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - establece el número de frames por defecto (por defecto 5, limitado a 1..10)"

local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "esMX")
if not L then return end

L["Left/Right (frames per press):"] = "Izquierda/Derecha (cuadros por pulsación):"
L["Up/Down (frames per press):"] = "Arriba/Abajo (cuadros por pulsación):"
L["Forward/Back (frames per press):"] = "Adelante/Atrás (cuadros por pulsación):"
L["Drag snap (degrees):"] = "Ajuste al arrastrar (grados):"
L["Rotate/Scale (frames per press):"] = "Rotar/Escalar (cuadros por pulsación):"
L["Usage: /bdt steps <1-10>"] = "Uso: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - establece la cantidad de cuadros por defecto (predeterminado 5, limitado a 1..10)"

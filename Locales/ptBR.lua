local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "ptBR")
if not L then return end

L["Left/Right (frames per press):"] = "Esquerda/Direita (frames por pressão):"
L["Up/Down (frames per press):"] = "Cima/Baixo (frames por pressão):"
L["Forward/Back (frames per press):"] = "Frente/Trás (frames por pressão):"
L["Drag snap (degrees):"] = "Encaixe ao arrastar (graus):"
L["Rotate/Scale (frames per press):"] = "Rotação/Escala (frames por pressão):"
L["Usage: /bdt steps <1-10>"] = "Uso: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - define a quantidade padrão de frames (padrão 5, limitado a 1..10)"

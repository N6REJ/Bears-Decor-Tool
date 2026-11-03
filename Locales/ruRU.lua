local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU")
if not L then return end

L["Left/Right (frames per press):"] = "Влево/вправо (кадров на нажатие):"
L["Up/Down (frames per press):"] = "Вверх/вниз (кадров на нажатие):"
L["Forward/Back (frames per press):"] = "Вперёд/назад (кадров на нажатие):"
L["Drag snap (degrees):"] = "Привязка при перетаскивании (градусы):"
L["Rotate/Scale (frames per press):"] = "Вращение/масштаб (кадров на нажатие):"
L["Usage: /bdt steps <1-10>"] = "Использование: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - задать количество кадров по умолчанию (по умолчанию 5, ограничено 1..10)"

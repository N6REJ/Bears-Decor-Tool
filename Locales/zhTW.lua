local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "zhTW")
if not L then return end

L["Left/Right (frames per press):"] = "左/右（每次按鍵幀數）:"
L["Up/Down (frames per press):"] = "上/下（每次按鍵幀數）:"
L["Forward/Back (frames per press):"] = "前/後（每次按鍵幀數）:"
L["Drag snap (degrees):"] = "拖曳吸附（度）:"
L["Rotate/Scale (frames per press):"] = "旋轉/縮放（每次按鍵幀數）:"
L["Usage: /bdt steps <1-10>"] = "用法: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - 設定預設幀數（預設 5，限制為 1..10）"

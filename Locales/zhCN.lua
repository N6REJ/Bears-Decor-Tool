local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "zhCN")
if not L then return end

L["Left/Right (frames per press):"] = "左/右（每次按键帧数）:"
L["Up/Down (frames per press):"] = "上/下（每次按键帧数）:"
L["Forward/Back (frames per press):"] = "前/后（每次按键帧数）:"
L["Drag snap (degrees):"] = "拖动吸附（度）:"
L["Rotate/Scale (frames per press):"] = "旋转/缩放（每次按键帧数）:"
L["Usage: /bdt steps <1-10>"] = "用法: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - 设置默认帧数（默认 5，限制为 1..10）"

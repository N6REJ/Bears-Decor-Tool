local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "koKR")
if not L then return end

L["Left/Right (frames per press):"] = "좌/우 (누를 때마다 프레임):"
L["Up/Down (frames per press):"] = "상/하 (누를 때마다 프레임):"
L["Forward/Back (frames per press):"] = "앞/뒤 (누를 때마다 프레임):"
L["Drag snap (degrees):"] = "드래그 스냅 (각도):"
L["Rotate/Scale (frames per press):"] = "회전/크기 (누를 때마다 프레임):"
L["Usage: /bdt steps <1-10>"] = "사용법: /bdt steps <1-10>"
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = "/bdt steps <n> - 기본 프레임 수 설정 (기본 5, 1..10 범위로 제한)"

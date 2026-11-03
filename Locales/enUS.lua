local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, true)

-- Core
L["Bears_Decor_Tool"] = true
L["Housing precision API is unavailable (%s)."] = true
L["This addon requires retail Midnight 12.1.5 or newer with Housing enabled."] = true
L["Open the House Editor first."] = true
L["Enter Expert Decor mode"] = true
L["Enter Expert Decor mode."] = true
L["Select a decor item"] = true
L["Select a decor item."] = true
L["Select a decor item first."] = true
L["Could not read the house editor state."] = true
L["Could not read the decor selection."] = true
L["Cannot pulse during combat lockdown."] = true
L["API unavailable"] = true
L["Ready - Translate"] = true
L["Ready - Rotate"] = true
L["Ready - Scale"] = true
L["Usage: /bdt pulse <type> [frames]"] = true
L["Unknown increment type: %s"] = true
L["Frames must be a number."] = true
L["Cannot commit: %s"] = true
L["Movement committed."] = true
L["Commit failed: %s"] = true
L["Usage: /bdt steps <1-10>"] = true
L["Default pulse frames set to %s."] = true
L["Debug logging enabled."] = true
L["Debug logging disabled."] = true
L["SavedVariables reset to defaults."] = true
L["Unknown command: %s"] = true
L["API: available"] = true
L["API: unavailable - %s"] = true
L["House editor: unknown"] = true
L["House editor: active"] = true
L["House editor: inactive"] = true
L["Expert Decor: yes"] = true
L["Nudging: %s"] = true
L["Nudging on."] = true
L["Nudging off."] = true
L["Nudging is off. Use /bdt on."] = true
L["/bdt on - turn nudging on"] = true
L["/bdt off - turn nudging off and stop pulses"] = true
L["Expert Decor: no"] = true
L["Decor selected: unknown"] = true
L["Decor selected: yes"] = true
L["Decor selected: no"] = true
L["Precision submode: %s"] = true
L["Default frames (steps): %s"] = true
L["Active pulses: none"] = true
L["Active pulses: %s"] = true

-- Pulse
L["Cannot pulse: unknown increment type."] = true
L["Could not resolve the precision submode for this increment."] = true
L["Precision API call failed: %s"] = true
L["Could not set precision submode: %s"] = true
L["Precision submode API is unavailable."] = true
L["Pulse driver failed; pulse stopped."] = true
L["Could not schedule the pulse safety timer; pulse stopped."] = true

-- UI
L["Stop"] = true
L["Commit"] = true
L["Keybinds"] = true
L["Steps: %s"] = true
L["Left/Right (frames per press):"] = true
L["Up/Down (frames per press):"] = true
L["Forward/Back (frames per press):"] = true
L["Drag snap (degrees):"] = true
L["Rotate/Scale (frames per press):"] = true
L["Wheel nudges forward/back. Relative nudges only."] = true
L["Increment type unavailable: %s"] = true
L["CommitDecorMovement is unavailable."] = true

-- Help
L["/bdt - toggle the window"] = true
L["/bdt show - show the window"] = true
L["/bdt hide - hide the window and stop pulses"] = true
L["/bdt pulse <type> [n] - pulse an increment type for n frames (default: steps)"] = true
L["/bdt stop - stop every increment type"] = true
L["/bdt status - print API, editor, selection, submode, steps, and active pulses"] = true
L["/bdt steps <n> - set the default frame count (default 5, clamped to 1..10)"] = true
L["/bdt commit - commit the selected decor movement"] = true
L["/bdt debug - toggle debug logging"] = true
L["/bdt reset - reset SavedVariables to defaults"] = true
L["/bdt help - print this help"] = true
L["Types: left, right, forward, back, up, down, rotateleft, rotateright, scaleup, scaledown"] = true

-- Options and minimap
L["Click to open or close the options."] = true
L["Drag to move this icon around the minimap."] = true

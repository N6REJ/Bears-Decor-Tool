local _, ns = ...

ns.Hold = ns.Hold or {}
local Hold = ns.Hold

-- One button per nudge direction. The Expert Decor arrow and Page keys are
-- bound to these buttons with SetOverrideBindingClick (see Core.lua). Each
-- button is registered for both key-down and key-up.
local BUTTON_NAMES = {
    left = "BearsDecorToolNudgeLeft",
    right = "BearsDecorToolNudgeRight",
    forward = "BearsDecorToolNudgeForward",
    back = "BearsDecorToolNudgeBack",
    up = "BearsDecorToolNudgeUp",
    down = "BearsDecorToolNudgeDown",
}

-- A press first runs the same one-frame pulse that /bdt pulse uses. If the key
-- is still down after this many seconds, the pulse is replaced by continuous
-- movement until the key is released.
local HOLD_DELAY_SECONDS = 0.3

function Hold.GetButtonName(key)
    return BUTTON_NAMES[key]
end

-- The press currently active for each key. Each press gets its own id, so a
-- delayed check from an earlier press cannot act on a later one.
local heldByKey = {}
local pressCount = 0

function Hold:OnKey(key, down)
    ns:Debug(string.format("override key %s: down=%s", tostring(key), tostring(down)))

    if not ns.Pulse then
        return
    end

    if down == nil then
        -- The click did not say whether this is a press or a release. Fall back
        -- to a one-frame pulse so the key still nudges.
        ns.NudgeByKey(key)
        return
    end

    if down then
        local incrementType, steps = ns:GetNudgeIncrementType(key)
        if incrementType then
            pressCount = pressCount + 1
            local press = { id = pressCount, incrementType = incrementType, held = false }
            heldByKey[key] = press

            ns.Pulse:Start(incrementType, steps)

            C_Timer.After(HOLD_DELAY_SECONDS, function()
                if heldByKey[key] == press then
                    press.held = true
                    ns.Pulse:HoldStart(incrementType)
                end
            end)
        end
    else
        local press = heldByKey[key]
        heldByKey[key] = nil
        -- A tap has already run as a pulse; releasing it does nothing more.
        if press and press.held then
            ns.Pulse:HoldStop(press.incrementType)
        end
    end

    if ns.UI and ns.UI.UpdateStatus then
        ns.UI:UpdateStatus()
    end
end

for key, name in pairs(BUTTON_NAMES) do
    local button = CreateFrame("Button", name, UIParent)
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetScript("OnClick", function(_, _, down)
        Hold:OnKey(key, down)
    end)
end

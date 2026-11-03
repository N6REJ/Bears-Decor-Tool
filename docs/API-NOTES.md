# Bears_Decor_Tool API notes

Research notes for the housing APIs used by this skeleton. These notes describe
the public API surface as documented for retail Midnight 12.1.5. The housing
APIs are new and may change between builds.

## Functions used

```lua
C_HousingExpertMode.SetPrecisionIncrementingActive(incrementType, active)
C_HousingExpertMode.SetPrecisionSubmode(subMode)
C_HousingExpertMode.GetPrecisionSubmode()
C_HousingExpertMode.IsDecorSelected()
C_HousingExpertMode.CommitDecorMovement()

C_HouseEditor.IsHouseEditorActive()
C_HouseEditor.ActivateHouseEditorMode(editMode)
```

`C_HouseEditor.ActivateHouseEditorMode` is documented here for completeness but
is not called by the skeleton. The addon never switches editor modes for the
player.

### Return values

- `GetPrecisionSubmode()` returns `Enum.HousingPrecisionSubmode?`.
- `IsDecorSelected()` returns a boolean.
- `IsHouseEditorActive()` returns a boolean.
- `CommitDecorMovement()` has no documented return value.
- `ActivateHouseEditorMode(editMode)` returns `Enum.HousingResult`.

## Enums

Always pass the enum table value, never a numeric literal or a string.

```lua
Enum.HousingIncrementType.Left        -- 0x1
Enum.HousingIncrementType.Right       -- 0x2
Enum.HousingIncrementType.Forward     -- 0x4
Enum.HousingIncrementType.Back        -- 0x8
Enum.HousingIncrementType.Up          -- 0x10
Enum.HousingIncrementType.Down        -- 0x20
Enum.HousingIncrementType.RotateLeft  -- 0x40
Enum.HousingIncrementType.RotateRight -- 0x80
Enum.HousingIncrementType.ScaleUp     -- 0x100
Enum.HousingIncrementType.ScaleDown   -- 0x200
```

```lua
Enum.HousingPrecisionSubmode.Translate -- 0
Enum.HousingPrecisionSubmode.Rotate    -- 1
Enum.HousingPrecisionSubmode.Scale     -- 2
```

```lua
Enum.HouseEditorMode.None                 -- 0
Enum.HouseEditorMode.BasicDecor           -- 1
Enum.HouseEditorMode.ExpertDecor          -- 2
Enum.HouseEditorMode.Layout               -- 3
Enum.HouseEditorMode.Customize            -- 4
Enum.HouseEditorMode.Cleanup              -- 5
Enum.HouseEditorMode.ExteriorCustomization -- 6
```

## Events used

```lua
HOUSE_EDITOR_MODE_CHANGED: currentEditMode
HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED: hasSelectedTarget, targetType
HOUSING_DECOR_PRECISION_SUBMODE_CHANGED: activeSubmode
HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED: isManipulatingSelection
```

Payloads:

- `currentEditMode` is an `Enum.HouseEditorMode`.
- `hasSelectedTarget` is a boolean; `targetType` is an
  `Enum.HousingExpertModeTargetType`.
- `activeSubmode` is an `Enum.HousingPrecisionSubmode?` (may be `nil`).
- `isManipulatingSelection` is a boolean.

`HOUSE_EDITOR_MODE_CHANGED` is the only mode signal available in the documented
API. The addon stores the latest `currentEditMode` and, before that event has
been seen, treats a non-nil precision submode as evidence that Expert Decor mode
is active. `GetPrecisionSubmode()` is used only as supporting evidence because
there is no documented "get current editor mode" function.

## Why an addon can call SetPrecisionIncrementingActive

The built-in Expert Decor keybindings use the function directly. The relevant
pattern is:

```lua
C_HousingExpertMode.SetPrecisionIncrementingActive(
    Enum.HousingIncrementType.Left,
    keystate == "down"
)
```

The public API metadata lists `SecretArguments = "AllowedWhenUntainted"` for
`SetPrecisionIncrementingActive`; the function is not marked protected. Addon
code loaded from an addon is untainted, so a normal click handler or slash
command should be allowed to call it. This skeleton keeps the call path direct
and does not route the API call through insecure or tainted data.

In-game verification of this call is still required. If the client blocks it,
capture the exact error and record it here.

## What is not available

- There is no public API to set absolute position, rotation, or scale.
- There is no public getter for exact position, rotation, or scale.
- `C_HousingExpertMode.GetSelectedDecorInfo()` exposes catalog/instance metadata
  (`decorGUID`, `decorID`, `name`, lock and permission flags, dye slots, size),
  but not the transform.
- The addon can only nudge relative to the current transform, by activating an
  increment type for a number of frames.

`HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED` reports whether a target is
selected and its target type, not its coordinates.

## Implementation notes

- `ACTIVE_FRAME_BIAS = 1` keeps the increment active for one extra
  `OnUpdate` tick so the C-side update sees at least one active frame. The
  resulting displacement is not guaranteed to equal the requested frame count.
- `MAX_ACTIVE_SECONDS = 3` is a hard safety cap. The driver frame checks it and
  an independent `C_Timer.After` backstop uses a token to stop stale pulses.
- `Start` first calls `StopAll`, so only one increment type is active at a time.
  Multi-axis and diagonal movement are future features.
- `StopAll` sets every known increment type to `false`, even if the internal
  state says it is inactive. This is the panic path used on UI hide, editor or
  selection changes, world transitions, logout, and `/hn stop`.
- API calls are wrapped in `pcall`; only the first failure in a pulse is
  printed.

## Open questions

- Does a one-frame pulse produce zero, one, or more increments?
- Is movement per frame fixed, or is it frame-time dependent?
- Does `CommitDecorMovement()` keep the decor selected?
- Is `SetPrecisionSubmode` immediate enough to call before starting a pulse, or
  must activation be deferred by one frame?
- Does the house exterior use the same increment types and precision submodes?
- Are the `*DebugInfo` functions restricted or unavailable to addons?
- Does `HOUSE_EDITOR_MODE_CHANGED` always fire before precision submodes become
  readable after a reload?

## Sources

Warcraft Wiki:

- <https://warcraft.wiki.gg/wiki/API:C_HousingExpertMode.SetPrecisionIncrementingActive>
- <https://warcraft.wiki.gg/wiki/API:C_HousingExpertMode.SetPrecisionSubmode>
- <https://warcraft.wiki.gg/wiki/API:C_HousingExpertMode.GetPrecisionSubmode>
- <https://warcraft.wiki.gg/wiki/API:C_HousingExpertMode.IsDecorSelected>
- <https://warcraft.wiki.gg/wiki/API:C_HousingExpertMode.CommitDecorMovement>
- <https://warcraft.wiki.gg/wiki/API:C_HousingExpertMode.GetSelectedDecorInfo>
- <https://warcraft.wiki.gg/wiki/API:C_HouseEditor.IsHouseEditorActive>
- <https://warcraft.wiki.gg/wiki/API:C_HouseEditor.ActivateHouseEditorMode>
- <https://warcraft.wiki.gg/wiki/Enum.HousingIncrementType>
- <https://warcraft.wiki.gg/wiki/Enum.HousingPrecisionSubmode>
- <https://warcraft.wiki.gg/wiki/Enum.HouseEditorMode>
- <https://warcraft.wiki.gg/wiki/Event:HOUSE_EDITOR_MODE_CHANGED>
- <https://warcraft.wiki.gg/wiki/Event:HOUSING_EXPERT_MODE_SELECTED_TARGET_CHANGED>
- <https://warcraft.wiki.gg/wiki/Event:HOUSING_DECOR_PRECISION_SUBMODE_CHANGED>
- <https://warcraft.wiki.gg/wiki/Event:HOUSING_DECOR_PRECISION_MANIPULATION_STATUS_CHANGED>
- <https://warcraft.wiki.gg/wiki/Structure_HousingDecorInstanceInfo>

Blizzard UI source: the built-in binding snippet comes from the retail housing
Expert Decor UI/binding code. A public mirror of the extracted interface files
is available at <https://github.com/Gethe/wow-ui-source>; search the housing
addons for `SetPrecisionIncrementingActive`. This repository did not bundle or
modify any Blizzard files.

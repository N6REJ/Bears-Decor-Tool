# HousingNudge

Micro-nudge the selected housing decor with the retail **Expert Decor** precision API.

HousingNudge is a small, dependency-free World of Warcraft addon that pulses
`C_HousingExpertMode.SetPrecisionIncrementingActive` for a configurable number
of frames. It is a skeleton and proof of concept, not a finished movement tool.

## Status

**Skeleton / proof of concept.** The addon is designed to load, detect the
housing API, and expose a movable nudge window. In-game verification of the
pulse behavior is still pending. Exact distances and coordinates are not
available through the public API.

## Requirements

- Retail World of Warcraft: Midnight, patch **12.1.5** or newer.
- A house and access to the **House Editor**.
- **Expert Decor** mode active.
- A decor item selected.
- Not in combat lockdown.

The TOC currently uses interface number `120105` (12.1.5). Verify the live
client value and update the TOC if it differs:

```text
/dump select(4, GetBuildInfo())
```

The TOC number has not been verified in a running client in this workspace.

## Installation

This repository root is the addon folder. For development, junction or clone it
into the retail AddOns directory so the folder name matches the TOC name:

```powershell
New-Item -ItemType Junction `
    -Path "C:\Gaming\World of Warcraft\_retail_\Interface\AddOns\HousingNudge" `
    -Target "E:\wow\Bears-Delve-Tool"
```

Then run `/reload` in game. If you copy files instead, the destination folder
must be named `HousingNudge` and contain `HousingNudge.toc`.

## Usage

1. Enter a house, open the House Editor, and switch to **Expert Decor**.
2. Select a decor item.
3. Run `/hn` to open the window.
4. Use the nudge buttons or a command such as `/hn pulse forward 1`.
5. Run `/hn stop` if you ever need to clear every increment type.

Examples:

```text
/hn
/hn status
/hn pulse forward 1
/hn pulse rotateleft 5
/hn steps 3
/hn pulse up
/hn stop
/hn commit
```

## Slash commands

| Command | Description |
| --- | --- |
| `/hn` | Toggle the window. |
| `/hn show` | Show the window. |
| `/hn hide` | Hide the window and stop all pulses. |
| `/hn pulse <type> [n]` | Pulse one increment type for `n` frames (default: saved steps). |
| `/hn stop` | Stop every increment type immediately. |
| `/hn status` | Print API, editor, selection, submode, steps, and active pulses. |
| `/hn steps <n>` | Set the default frame count (default 5, clamped to `1..60`). |
| `/hn commit` | Call `CommitDecorMovement()` when a decor is selected. |
| `/hn debug` | Toggle debug logging. |
| `/hn reset` | Reset SavedVariables to defaults. |
| `/hn help` | Print command help. |

Both `/hn`, `/housingnudge`, `/bdt`, and `/delvetool` are registered.

Accepted `<type>` names, case-insensitive:

```text
left, right, forward, back, up, down,
rotateleft, rotateright, scaleup, scaledown
```

The parser uses an explicit whitelist; arbitrary strings are rejected. No
`loadstring` is used on user input.

## Keybinds and mouse

Default keybinds, configurable in WoW's Key Bindings UI under **HousingNudge**:

- Left Arrow: nudge Left
- Right Arrow: nudge Right
- Page Up: nudge Forward
- Page Down: nudge Back

Mouse wheel on the HousingNudge window nudges Forward/Back by the saved step count.
The **Keybinds** button opens the Key Bindings UI.

## How it works

While an increment type is active and a decor target stays selected, the game
applies incremental movement every frame. HousingNudge switches to the matching
precision submode, calls `SetPrecisionIncrementingActive(type, true)` once, and
keeps it active for the requested frame count plus `ACTIVE_FRAME_BIAS`
(one extra tick). It then calls `false` exactly once. A hard three-second cap,
an independent `C_Timer.After` backstop with a token check, and a panic
`StopAll()` path make sure an increment type is never left active.

The addon stops all pulses when the window hides, the editor mode changes, the
decor selection changes, the player enters the world or logs out, and on
`/hn stop`.

## Limitations

- Relative nudging only. There is no public API to set absolute position,
  rotation, or scale.
- No exact coordinates or transform readout. `GetSelectedDecorInfo()` does not
  expose the transform.
- The frame count is not a guaranteed distance. Calibrate the step in game and
  expect differences at different frame rates.
- The housing API is new and may change between patches.
- Only one increment type is active at a time. Multi-axis, diagonal, and
  hold-to-move behavior are not implemented.
- Not affiliated with Blizzard Entertainment.

## Testing checklist

In-game verification is pending. When testing, record the results in
`docs/API-NOTES.md` or a follow-up issue:

1. Install the addon and run `/reload`.
2. Enter a house, open the House Editor, switch to Expert Decor, and select a
   decor item.
3. Run `/hn status` and confirm the API, editor, selection, and submode values.
4. Run `/hn pulse forward 1`; confirm the decor moves slightly and stops.
5. Try 2, 5, and 10 frames. Record whether displacement is linear.
6. Repeat at 30 FPS, 60 FPS, and uncapped FPS. Record whether a fixed frame
   count produces a different distance.
7. Change decor selection during a pulse; confirm it stops.
8. Run `/hn stop` immediately after starting a pulse; confirm it stops.
9. Close the window during a pulse; confirm it stops.
10. Run `/hn commit`; record whether the decor stays selected.
11. If a call is blocked, capture the exact error and update
    `docs/API-NOTES.md`.

## File layout

```text
HousingNudge.toc       Addon manifest and load order
Core.lua               Namespace, SavedVariables, capability checks, events, slash commands
Pulse.lua              Frame-counted pulse engine, safety cap, timer backstop
UI.lua                 Movable nudge window
README.md              This file
CHANGELOG.md           Version history
docs/API-NOTES.md      API research, restrictions, and open questions
scripts/package.ps1    Optional local zip packaging
```

## Intentionally not implemented yet

Keybindings, a settings/profile panel, a minimap icon, automatic show/hide,
continuous hold-to-move, multi-axis movement, step presets, automatic commits,
localization, Classic support, and CI/publishing are out of scope for this
skeleton.

## License

MIT. See `LICENSE`.

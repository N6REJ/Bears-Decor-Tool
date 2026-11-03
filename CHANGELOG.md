# Changelog

## Unreleased

- Removed `Bindings.xml` and the global nudge functions it called. The Expert Decor arrow and Page keys handle nudging directly. The Key Bindings UI actions are gone.
- The window title, minimap tooltip, and chat prefix now read "Bears Decor Tool" instead of "Bears_Decor_Tool".
- Added hold-to-move for the Expert Decor arrow and Page keys. A tap moves one step, as `/bdt pulse` does. Holding past 0.3 seconds keeps the decor moving until the key is released, capped at 10 seconds. Not verified in game.
- Added a minimap button that opens and closes the window. Drag it to move it around the minimap. It uses LibDBIcon-1.0 and LibDataBroker-1.1, vendored under `Libs/`. Its saved position is in `BearsDecorToolDB.minimap`. Not verified in game.
- Expert Decor arrow and Page keys are now bound with `SetOverrideBindingClick` to addon buttons, which report key-down and key-up.
- Added `/bdt resetsnap`. It restores `housingExpertGizmos_Rotation_SnapDegrees` and `housingExpertGizmos_SnapOnHold` to the defaults (`SnapOnHold` = `1`, the default documented by Advanced Decoration Tools). It is meant to reverse the SHIFT snap left by earlier builds. Runs only when typed. Not verified in game.
- The only slash command is now `/bdt`. The aliases `/hn`, `/Decortool`, `/bearsDecortool`, and `/housingnudge` are removed.
- Added per-direction step fields (left/right, up/down, wheel, other) to the panel.
- Nudge keybinds and buttons now use the matching per-direction step value.
- Renamed the "Mouse (wheel)" step slider to "Rotation" with a 1-60 range.
- Left/Right, Up/Down, Forward/Back, and Rotate/Scale step sliders (and `/bdt steps`) now max at 10.
- Added `/bdt on` and `/bdt off` to turn nudging on or off. The setting is saved, `/bdt status` shows it, and `/bdt off` stops pulses and removes the Expert Decor arrow-key overrides.
- Increased the vertical spacing between step sliders in the window.
- Renamed the step sliders to "(frames per press)" so the labels say what the value does. Each value is a frame count per press, not degrees.
- Temporarily removed the drag snap slider. It had no effect in game. Its CVar writes are removed, and its saved value is no longer used.
- Rotate Left and Rotate Right arrow nudges use the Rotate/Scale step (frames) again. The saved key `stepWheel` is renamed `stepRotation`.
- `/bdt pulse <type>` without a frame count now uses that type's step, the same as the key press.

## 0.1.0

- Initial Bears_Decor_Tool skeleton for retail Midnight 12.1.5+.
- Added capability detection for the housing precision API.
- Added a movable nudge window with translate, rotate, scale, step, stop, and commit controls.
- Added a frame-counted pulse engine with a single active increment type, a hard three-second cap, and an independent timer backstop.
- Added `/hn` and `/Bears_Decor_Tool` commands for pulsing, status, steps, stop, commit, debug, reset, and help.
- Added SavedVariables for step count, debug logging, and window position.
- Documented the API contract, restrictions, limitations, and open questions.

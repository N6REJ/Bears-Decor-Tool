# Project guidance

- Bears_Decor_Tool targets retail World of Warcraft only (Midnight 12.1.5+). Do not add Classic support.
- Keep the addon Lua 5.1 compatible. AceLocale-3.0 is vendored under Libs/ for localization.
- Use only the housing functions, enums, events, and game CVars documented in `docs/API-NOTES.md`.
- Write a CVar only in response to an explicit user setting change, never on load or when a window opens.
- Keep the folder name, TOC filename, addon name, and SavedVariables prefix (`BearsDecorToolDB`) consistent.
- Do not modify Blizzard frames, hook housing UI, call protected functions, or simulate input.
- Every pulse must stop on UI hide, editor mode change, decor selection change, world transitions, `/bdt off`, and `/bdt stop`.
- Keep the pulse path untainted: call the housing API directly from addon code with the documented enum values.
- Split new feature code into small files and add each runtime file to `Bears_Decor_Tool.toc`.
- Update `README.md`, `docs/API-NOTES.md`, and `CHANGELOG.md` when behavior or API assumptions change.

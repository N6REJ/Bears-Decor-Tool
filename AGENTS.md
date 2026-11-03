# Project guidance

- HousingNudge targets retail World of Warcraft only (Midnight 12.1.5+). Do not add Classic support.
- Keep the addon Lua 5.1 compatible and dependency-free. Do not add Ace3, LibStub, or other libraries.
- Use only the housing functions, enums, and events documented in `docs/API-NOTES.md`.
- Keep the folder name, TOC filename, addon name, and SavedVariables prefix (`HousingNudgeDB`) consistent.
- Do not modify Blizzard frames, hook housing UI, call protected functions, or simulate input.
- Every pulse must stop on UI hide, editor mode change, decor selection change, world transitions, and `/hn stop`.
- Keep the pulse path untainted: call the housing API directly from addon code with the documented enum values.
- Split new feature code into small files and add each runtime file to `HousingNudge.toc`.
- Update `README.md`, `docs/API-NOTES.md`, and `CHANGELOG.md` when behavior or API assumptions change.

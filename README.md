# Bears Delve Tool

Base skeleton for a World of Warcraft addon built with Ace3, LibDataBroker, and LibDBIcon.

## What's included

- AceAddon bootstrap with AceConsole slash commands and AceEvent support.
- AceDB profile defaults (`BearsDelveToolDB`).
- Options panel registered with AceConfig and added to the Blizzard AddOns settings.
- LibDBIcon minimap launcher.
- Localized strings through AceLocale (`Locales/enUS.lua`).
- CurseForge/WoW packager metadata in `.pkgmeta`.
- Ace3/LibDataBroker/LibDBIcon libraries in `Libs/` (gitignored locally; the packager fetches them for releases).

## Commands

- `/bdt` or `/delvetool` — open the options panel.
- `/bdt debug` — toggle debug chat messages.
- `/bdt reset` — restore settings to their defaults.

## Project layout

```text
Bears_Delve_Tool.toc   Addon manifest and load order
core.lua               AceAddon bootstrap, database, slash commands, minimap button
options.lua            AceConfig options panel
Locales/enUS.lua       User-facing strings
Libs/                  Vendored libraries
```

## Adding features

1. Create a new Lua file (for example `modules/Delve.lua`).
2. Register a module with `addon:NewModule("Delve")`, using `addonTable.addon` from the file header.
3. Add the file to `Bears_Delve_Tool.toc` after `core.lua`.
4. Put any new user-facing text in `Locales/enUS.lua`.

## Installation

Copy or symlink this folder into `World of Warcraft/_retail_/Interface/AddOns/Bears_Delve_Tool`. The addon folder name must match the `.toc` file name.

The release package uses `Bears_Delve_Tool` as its folder name through `.pkgmeta`.

## License

MIT. See `LICENSE`.

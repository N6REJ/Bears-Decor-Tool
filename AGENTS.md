# Project guidance

- Use Ace3 libraries for addon functionality wherever an appropriate Ace library exists; do not reimplement that functionality with raw WoW APIs.
- Add the Ace3 libraries used by the addon as dependencies in its `.toc` and `.pkgmeta`, following the libraries' documented setup.
- Keep user-facing strings in `Locales/enUS.lua` through AceLocale; US English is the only supported locale for now.
- The addon name is `Bears_Delve_Tool`; saved variables are stored in `BearsDelveToolDB`.
- Add new feature code as AceAddon modules and load each file from the `.toc`.

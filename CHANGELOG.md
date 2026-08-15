# Changelog

All notable changes to HELMdiel are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.2] - 2026-08-15

### Changed

- **Releases now carry a `HELMdiel.zip`** that extracts to a folder named
  `HELMdiel`, ready to drop into `addons` without renaming.

### Fixed

- **Minimum Data keeps your character name off the filename too**, not just out
  of the rows. It writes `HELMdiel_export.csv`.

## [0.9.1] - 2026-08-14

### Fixed

- **Back-to-back gathers are no longer missed** when working a point at full
  speed.

### Added

- **A Minimum Data checkbox** under Export CSV. Cuts the export to Activity,
  Zone, Item, Count, Zone Gathers and Drop Rate, so you can share it without
  your character name attached.

### Changed

- **Export CSV** has moved above the reset buttons.
- `/helmdiel debug` now prints the gap between gathering events.

## [0.9.0] - 2026-08-14

### Renamed to HELMdiel

HHelmet is now HELMdiel, and `/hhelmet` is now `/helmdiel`.

If you were running the old version, **your gathered data does not move on its
own.** With the game closed:

1. Rename `config/addons/HHelmet` to `config/addons/HELMdiel`.
2. Delete the old `addons/HHelmet` folder and install `HELMdiel` in its place.

That config folder holds everything you have gathered, on every character.
Load the new addon before renaming that folder and it will start an empty file
and overwrite whatever you move in afterwards.

Everything below this point shipped as HHelmet, and still is HHelmet if you
download one of those releases. Those entries name it accordingly.

### UI Rework

The window is being rebuilt. Expect it to keep changing through the 0.9.x
releases as it settles, with 1.0 as the point where it stops moving.

### Added

- **Item icons**, drawn from the game's own art, so there is nothing extra to
  download.
- **Rarity colours** on each item's name and border: white Common, green
  Uncommon, blue Rare, purple Very Rare, orange Extremely Rare. They replace
  the `Common` and `Uncommon` headings.
- **A Spoils tab**, before Settings: an alphabetical tally of everything
  gathered this session, with its own reset button.
- **Export CSV** at the bottom of Settings. Writes a spreadsheet next to your
  settings, one row per item per zone, and prints the path in chat.
- **The addon version in the title bar.**
- New Settings: **Item Icons**, **Icon Size** (Large or Small), **Item Style**
  (Grid or List), **Opacity**, **UI Scale** (75%, 100%, 125%) and
  **Auto-Resize Window**.

### Changed

- **Gathered items are cards rather than lines of text**: an icon in a
  rarity-coloured border with the name and drop rate beside it, three to a row
  as a Grid or one per row as a List. Per-item counts are gone.
- **The window is semi-transparent black with rounded corners**, in Segoe UI
  Bold with gold labels and charcoal chrome. Destructive buttons are red.
- **The tabs are a row of buttons** rather than an attached strip.
- **The window is wider.** Turn off Auto-Resize Window, or pick Small icons and
  the List style, to bring it back down.
- **Settings is shorter**, with the activity checkboxes and skill boxes two to
  a row.
- The reset button is now **Reset Gather/Skill Ups**, and it clears the Spoils
  tab too.
- Home shows Gathers and Skill Ups on one line. The `Items logged` total and
  the `Current Zone` line are gone, though both are still tracked.

## [0.8.0] - 2026-08-14

### Changed

- Nothing you can see. The addon was split from one file into six, so **copy
  the whole folder when you update**, not just `HHelmet.lua`.
- Closed item foldouts no longer recount their contents every frame.

## [0.7.1] - 2026-08-12

### Added

- **Home Minimum Mode** in Settings, leaving Home with just your skill and the
  current zone's fatigue. Tracking carries on underneath.

### Changed

- **FATIGUED appears only when the game says a zone is tapped out**, not when
  the counter reaches 200. The counter drifts if you gather with the addon
  unloaded, so the cap alone is not proof.
- The fatigue message now resets every other zone for that activity to zero,
  which repairs that drift.

## [0.7.0] - 2026-08-12

### Added

- **A checkbox per activity** in Settings to remove it from the window. Hiding
  does not stop tracking.
- **Reset Session**, clearing only the Gathers and Skill ups counters and
  keeping your fatigue, items and skill. **Reset All Data** still clears
  everything.

### Changed

- **Item names read the way your inventory shows them**, abbreviations
  included, looked up from the game's own item data.
- Items sort by how often they drop, most common first, instead of
  alphabetically.
- Zones with no fatigue are hidden.
- The window is narrower.

### Fixed

- Breaking a tool counts as a gathering attempt. Breaks that yielded nothing
  were missing from your success rate.

## [0.6.1] - 2026-08-12

### Added

- Home counts attempts as well as successes, with a success rate, and shows
  skill ups against the same attempt count. Every skill up counts as one
  whatever its size, and skill ups from failed gathers count too.
- Failed gathers are detected so they count as attempts. They still do not
  affect fatigue.

### Changed

- The item drop list carries its own total. Drop history is kept across resets
  so percentages stay meaningful, so it deliberately differs from the gather
  counters.

### Known limitations

- Skill up rates are likely tied to your skill against each zone's skill range,
  which HHelmet does not track. Rates from different skill levels are not
  comparable.
- Two of Logging's messages are unverified: its failure, and breaking a hatchet
  while still getting a log. Either may go uncounted.

## [0.6.0] - 2026-08-11

### Added

- **Home tab**, shown first, covering only the zone you are standing in. Zones
  supporting two activities get a section for each.
- **Settings tab**, holding the skill boxes, the auto-open toggle and the reset
  button.
- **Skill tracking**, read from skill-up messages, with
  `/hhelmet skill <activity> <value>` to set a level manually.

### Fixed

- Every gather wrote your settings file to disk twice.
- Opening the window added empty entries for activities and zones you had never
  gathered in.

## [0.5.1] - 2026-08-11

### Fixed

- **Excavation, Logging and Mining now detect gathers.** All three shipped with
  guessed chat patterns that never matched, so their counters stayed at zero.
- Mining gathers are no longer counted as Excavation. The two emit identical
  text, so the current zone decides between them.

### Changed

- Detection is no longer broken by chat addons that prefix lines with a
  timestamp.

## [0.5.0] - 2026-08-11

Initial public release.

### Added

- Per-zone fatigue tracking for all four HELM activities, capped at 200 and
  persisted per character.
- An ImGui window with a tab per activity and a coloured bar per tracked zone.
- Item drop logging per zone, grouped into rarity tiers.
- The `/hhelmet` command set: `show`, `hide`, `debug`, `reset all`,
  `reset <activity>`, `reset <activity> zone`, and `set <activity> <0-200>`.
- Auto-open on gather.

### Known limitations

- Only Harvesting's chat patterns are confirmed against real HorizonXI text.
  The other three use best guesses and may not count correctly.
- Zone IDs use standard retail-compatible numbering and have not been checked
  against HorizonXI's server.
- The rule that a gather decays *all* other zones for that activity was
  inferred from a two-zone observation.

[Unreleased]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.2...HEAD
[0.9.2]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.7.1...v0.8.0
[0.7.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/KisamMeow/HELMdiel/releases/tag/v0.5.0

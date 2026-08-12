# Changelog

All notable changes to HHelmet are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.1] - 2026-08-12

### Added

- The Home tab now tracks your attempts, not just your successes. It shows how
  many gathers gave you an item out of how many you tried, with a success rate.
- Skill ups earned in the current zone are shown against that same attempt
  count, with a percentage. Every skill up counts as one, whether it raised
  your skill by 0.1 or 0.3, and skill ups from failed gathers count too.
- Failed gathers are now detected so they can be counted as attempts. They
  still do not affect fatigue.

### Changed

- The item drop list on Home is now labelled with its own total, which is
  separate from the gather counters. Drop history is kept so percentages stay
  meaningful, while the gather counters measure effort from when counting
  began, so the two numbers differ on purpose.

### Known limitations

- Skill up rates are likely tied to your skill level against each zone's skill
  range, which HHelmet does not track. Rates recorded at different skill levels
  are not directly comparable.
- Two of Logging's messages are unverified: its failure, and the one for
  breaking a hatchet while still getting a log. Failed logging attempts may go
  uncounted, and a logging gather that breaks your hatchet may be missed.

## [0.6.0] - 2026-08-11

### Added

- **Home tab**, shown first, covering only the zone you're standing in: skill,
  fatigue, and gathered items. Zones supporting two activities (Yuhtunga and
  Yhoator Jungle) get a section for each.
- **Settings tab**, holding a box for each skill level, the auto-open toggle,
  and the Reset Session button.
- **Skill tracking.** Skill levels are read from skill-up messages and shown at
  the top of each activity tab.
- `/hhelmet skill <activity> <value>` to set a skill level manually, since the
  game only reveals your skill when it increases.

### Fixed

- Every gather wrote your settings file to disk twice instead of once.
- Having the window open added empty entries to your settings file for
  activities and zones you had never gathered in.

## [0.5.1] - 2026-08-11

### Fixed

- Excavation, Logging, and Mining now detect gathers. All three shipped with
  guessed chat patterns that never matched anything, so their counters stayed
  at zero. Confirmed strings are `You successfully dig up` (Excavation and
  Mining) and `You successfully cut off` (Logging).
- Mining gathers are no longer counted as Excavation. The two activities emit
  identical success text, and the first match won; the current zone now
  decides between them.

### Changed

- Detection is no longer affected by chat addons that prefix lines with a
  timestamp.

## [0.5.0] - 2026-08-11

Initial public release.

### Added

- Per-zone fatigue tracking for all four HELM activities (Harvesting,
  Excavation, Logging, Mining), capped at 200 and persisted per character.
- ImGui window with one tab per activity, a colored progress bar per tracked
  zone, and a `(here)` marker on your current zone.
- Item drop logging per zone, grouped into rarity tiers (Common through
  Extremely Rare) and sorted by tier, then alphabetically.
- `/hhelmet` command set: `show`, `hide`, `debug`, `reset all`,
  `reset <activity>`, `reset <activity> zone`, and `set <activity> <0-200>`.
- Auto-open on gather, toggleable from the window.
- `debug` mode that prints raw incoming chat lines, for calibrating message
  detection against the live server.

### Known limitations

- Only Harvesting's chat patterns are confirmed against real HorizonXI text.
  Excavation, Logging, and Mining use unverified best guesses and may not
  count correctly. See the README for how to report the real strings.
- Zone IDs use standard retail-compatible numbering and have not been checked
  one-by-one against HorizonXI's server.
- The rule that a gather decays *all* other zones for that activity was
  inferred from a two-zone observation, not stress-tested against three or
  more fatigued zones at once.

[Unreleased]: https://github.com/KisamMeow/HHelmet/compare/v0.6.1...HEAD
[0.6.1]: https://github.com/KisamMeow/HHelmet/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/KisamMeow/HHelmet/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/KisamMeow/HHelmet/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/KisamMeow/HHelmet/releases/tag/v0.5.0

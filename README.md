# HELMdiel

Tracks HorizonXI's HELM system: Harvesting, Excavation, Logging and Mining.

This addon is in very early development, there will be bugs and the UI will be reworked as I get closer to being feature complete.

Ashita v4.30+ addon. Version 0.9.8. Released under GPL-3.0. Coded with help from Claude Opus 5.

## Features

- Per-zone fatigue counters for all four activities, persisted per character.
- Skill levels read automatically from your skill-up messages.
- Attempts, successes and skill ups per zone, so you can see what a zone costs.
- Item drop logging with icons, grouped into rarity tiers.
- A Spoils tab tallying everything gathered this session.
- Export to CSV for Excel or Sheets.

## Coming soon

No promised timeline:

- Gil per hour on the Spoils tab, using prices you set yourself
- Rank tracking
- More of the UI rework

## Installation

**Requires Ashita v4.30 or newer.**

Download **HELMdiel.zip** from the
[latest release](https://github.com/KisamMeow/HELMdiel/releases/latest) and
extract it into your Ashita `addons` directory, then:

```
/addon load HELMdiel
```

Take `HELMdiel.zip`, not the `Source code` archives. Those extract to a folder
with the version number attached, which Ashita will not load until it is
renamed.

To load it every time, add that line to `Ashita/scripts/default.txt`.

## Commands

`/hd` is a short alias for `/helmdiel` and takes all the same arguments.

| Command | What it does |
|---|---|
| `/helmdiel` | Toggles the window |
| `/helmdiel show` / `hide` | Shows or hides it |
| `/helmdiel debug` | Prints raw chat lines, for reporting detection problems |
| `/helmdiel set <activity> <value>` | Sets the current zone's fatigue |
| `/helmdiel skill <activity> <value>` | Sets your skill level |
| `/helmdiel reset all` | Wipes everything for this character |
| `/helmdiel reset <activity>` | Wipes one activity, all zones |
| `/helmdiel reset <activity> zone` | Wipes one activity, current zone only |

## How fatigue works

Each activity has its own counter **per zone**, capped at 200 by default.

- A successful gather raises the current zone's counter by 1.
- The same gather lowers every **other** tracked zone by 1.
- At the cap the zone is done: nothing more can be gathered there until you
  work the same activity somewhere else.

So if Giddeus is capped and you harvest 100 times in West Sarutabaruta,
Giddeus falls to 100.

**Zones you have outskilled hold more.** For every 10 skill levels above a
zone's skill cap you get 50 extra fatigue there, so West Sarutabaruta, which
caps harvesting at 10, holds 300 once you are at 35. This only applies to zones
whose skill cap the addon knows; the rest stay at 200.

The counters are a model built from observed play, not a readout of the
server's real numbers. If you gather with the addon unloaded they will drift;
`/helmdiel set` puts them back.

**The game corrects the drift itself.** When it tells you a zone is tapped
out, that zone is marked fatigued and every other zone for that activity drops
by however far this one just jumped, which is what the gathers you did not see
would have done. For the same reason the red **FATIGUED** label only appears
once the game has actually said so, since a counter sitting at the cap may just
have drifted.


## Reading the window

**Home** covers only the zone you are standing in. Zones with two activities
(Yuhtunga and Yhoator Jungle) get a section for each.

```
Harvesting Skill: 31.3   Skill Ups - 2/28 (7.1%)
Items Collected - 241    Last Skill Up - 12
```

**Skill Ups** is how often a swing in this zone raised your skill.

**Items Collected** is everything logged in this zone, and it survives resets
so your drop percentages stay meaningful. **Last Skill Up** is how many swings
ago it was, failures and broken tools included, and it carries across zones
because your skill does.

It reads **Cap (20)** once your skill reaches the zone's ceiling, naming the
cap, since the count is then measuring a drought the zone cannot end. Only a
few zones have a known cap; the rest show the count regardless.

Under each skill is how often that activity's special skills fire, in this
zone. **Gatherer's Discipline**, **Gold Rush** and **Motherlode** count against
the Items Collected figure below them. **Practiced Technique** counts against
the pickaxes that broke or would have, since it fires instead of a break.
Logging's are not known yet, so it shows none. The activity tabs carry the same
rates inside each zone's foldout, against that zone's own Items Collected.

These start counting from 0.9.6, while Items Collected goes back as far as your
drop history does. **If you gathered before 0.9.6, use Reset All Data for an
accurate rate**, after exporting if you want to keep the drop data. Reset
Gather/Skill Ups deliberately keeps both, so it will not fix this.

Fatigue bar colours, as a share of that zone's own cap:

| Colour | Fatigue | At a 200 cap | At a 300 cap |
|---|---|---|---|
| Light blue | below 75% | 0 to 149 | 0 to 224 |
| Yellow | 75% and up | 150 to 199 | 225 to 299 |
| Red | at the cap | 200 | 300 |

Red is the counter reaching the cap. The **FATIGUED** label is separate and
only appears when the game itself says the zone is tapped out.

Each item shows its icon in a border coloured by rarity, with its name in the
same colour, so you can read rarity without a label:

| Tier | Colour | Share of that zone's gathers |
|---|---|---|
| Common | White | 20% or more |
| Uncommon | Green | 10 to 19% |
| Rare | Blue | 5 to 9% |
| Very Rare | Purple | 1 to 4% |
| Extremely Rare | Orange | under 1% |

Items sort by how often they drop. **The percentages are only as good as your
sample.** Twenty gathers will show wildly misleading tiers; give it a few
hundred.

Skill starts as `unknown`, because the game only reports it when it goes *up*.
Type it into Settings or wait for your next skill up.

**The next four tabs** are one per activity: your skill, the zones you have
fatigue in, and a foldout of drops per zone.

**Spoils** is everything gathered this session in one alphabetical list,
whatever zone it came from:

```
[icon]  Bone Chip              x3
[icon]  Sprig of Dyer's Woad   x12
```

No rates, no rarity, just what you are carrying home. It survives reloading
and logging out.

## Settings

| Setting | What it does |
|---|---|
| Home Minimum Mode | Home shows only skill and fatigue. Tracking continues |
| Item Icons | Item art beside each drop. On by default |
| Icon Size | Large or Small. The rarity border is drawn either way |
| Item Style | Grid packs three across, List gives each item a row and is far narrower |
| Opacity | How see-through the window is. Stops short of invisible |
| UI Scale | 75%, 100% or 125%. Text, icons and spacing together |
| Shown activities | Unchecking one hides its tab. Tracking continues |
| Skill levels | Type in a level the game has not told the addon yet |
| Auto-open on gather | The window pops up when you gather |
| Auto-Resize Window | On, it fits its contents. Off, drag the gold corner yourself |

**Export CSV** writes a spreadsheet and prints its path in chat:

```
Ashita/config/addons/HELMdiel/<Character>_export_2026-08-16_134501.csv
```

One row per item per zone, with that zone's drop rate, fatigue and counters
alongside, which drops straight into a pivot table.

Every export is stamped with the date and time, so they pile up beside each
other in date order rather than overwriting.

**Minimum Data**, the checkbox under it, cuts the export down to Activity,
Zone, Item, Count, Zone Gathers, Drop Rate and Skill. Your character name,
fatigue, attempts, successes and skill ups are left out, so you can share your
drop data without attaching who you are. Skill stays because drop and skill-up
rates only mean something against the skill they were gathered at.

Your name comes off the filename too, so a minimal export writes
`HELMdiel_export_<date>_<time>.csv` instead.

Two reset buttons:

- **Reset Gather/Skill Ups** clears the Home counters and the Spoils tab. Your
  fatigue, drop history, skill levels and special skill counts are kept, since
  those last two are measured against the drop history. This starts a new
  session.
- **Reset All Data** clears everything for this character.

## Detection status

Detection reads your chat log. **All four activities are verified against real
HorizonXI messages.**

Excavation and Mining both say "You successfully dig up", so HELMdiel tells
them apart by the zone you are in. That works because no zone appears in both
lists. Gather either in an untracked zone and it may be filed under the wrong
one.

Two messages have not been seen directly yet:

- **Logging's message for breaking a hatchet while still getting a log.** It
  matches what the older `hgather` addon uses.
- **The fatigue-cap message**, verified for Harvesting and assumed shared.

If something is not being counted, run `/helmdiel debug`, gather with the tool
in question, and send the exact lines.

## Tracked zones

- **Harvesting**: West Sarutabaruta, Giddeus, Yuhtunga Jungle, Yhoator Jungle,
  Bhaflau Thickets, Wajaom Woodlands
- **Excavation**: Attohwa Chasm, Korroloka Tunnel, Maze of Shakhrami, Tahrongi
  Canyon
- **Logging**: Buburimu Peninsula, Carpenters' Landing, East Ronfaure, Ghelsba
  Outpost, Jugner Forest, Lufaise Meadows, Misareaux Coast, Yhoator Jungle,
  Yuhtunga Jungle, Caedarva Mire, Mamook
- **Mining**: Gusgen Mines, Ifrit's Cauldron, Newton Movalpolos, Oldton
  Movalpolos, Palborough Mines, Yughott Grotto, Zeruhn Mines

Gathering outside these lists still tracks fatigue, but it is not shown and
its drops are not logged.

## Data

Stored per character at:

```
Ashita/config/addons/HELMdiel/<Character>_<id>/settings.lua
```

Deleting that file resets the character, same as `/helmdiel reset all`.

## Known limitations

- **The raised fatigue cap only applies to zones whose skill cap is known**,
  and that is 7 of the 28 tracked zones. Everywhere else the bar tops out at
  200, so if you have outskilled one of those zones the game will let you keep
  gathering after the bar looks full. Sending me a zone's skill cap is the most
  useful correction you can make right now.
- **Skill up rates depend on your skill against a zone's cap**, which HELMdiel
  does not model. Rates recorded at different skill levels are not comparable,
  and a zone that looks slow may just be a poor match for your current skill.
- **A logging gather that breaks your hatchet may not be counted at all.** That
  message is the one detection pattern never seen in a real chat log, so if the
  wording differs the whole gather is missed: no item, no fatigue, no attempt.
  The other three activities are confirmed.
- **The fatigue message is confirmed for harvesting only** and assumed to be
  worded the same for the other three. If it differs, the red FATIGUED label
  will never appear for that activity and its counters will not resync.
- Zone IDs use standard retail-compatible numbering and have not been checked
  one by one against HorizonXI's server.

## Feedback

Zone skill caps are the most useful thing you can send right now, since they
drive the fatigue ceiling and only 7 zones have one. Corrections to the message
patterns and zone lists are next, and `/helmdiel debug` output is ideal.

Open an issue at
[github.com/KisamMeow/HELMdiel/issues](https://github.com/KisamMeow/HELMdiel/issues),
or DM me on Discord. I am Masuru in HorizonXI.

## Credits

Written by Masuru for HorizonXI. Thanks to the Ashita development community.

## License

HELMdiel is free software, released under the GNU General Public License,
version 3. See [LICENSE](LICENSE) for the full text.

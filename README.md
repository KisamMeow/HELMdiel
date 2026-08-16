# HELMdiel

Tracks HorizonXI's HELM system: Harvesting, Excavation, Logging and Mining.

This addon is in very early development, there will be bugs and the UI will be reworked as I get closer to being feature complete.

Ashita v4.30+ addon. Version 0.9.4. Released under GPL-3.0. Coded with help from Claude Opus 5.

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

| Command | What it does |
|---|---|
| `/helmdiel` | Toggles the window |
| `/helmdiel show` / `hide` | Shows or hides it |
| `/helmdiel debug` | Prints raw chat lines, for reporting detection problems |
| `/helmdiel set <activity> <0-200>` | Sets the current zone's fatigue |
| `/helmdiel skill <activity> <value>` | Sets your skill level |
| `/helmdiel reset all` | Wipes everything for this character |
| `/helmdiel reset <activity>` | Wipes one activity, all zones |
| `/helmdiel reset <activity> zone` | Wipes one activity, current zone only |

## How fatigue works

Each activity has its own counter **per zone**, capped at 200.

- A successful gather raises the current zone's counter by 1.
- The same gather lowers every **other** tracked zone by 1.
- At 200 the zone is done: nothing more can be gathered there until you work
  the same activity somewhere else.

So if Giddeus is capped and you harvest 100 times in West Sarutabaruta,
Giddeus falls to 100.

The counters are a model built from observed play, not a readout of the
server's real numbers. If you gather with the addon unloaded they will drift;
`/helmdiel set` puts them back.

**The game corrects the drift itself.** When it tells you a zone is tapped
out, that zone is marked fatigued and every other zone for that activity
resets to zero, which is what capping a zone from empty would have done
anyway. For the same reason the red **FATIGUED** label only appears once the
game has actually said so, since a counter sitting at 200 may just have
drifted.

## Reading the window

**Home** covers only the zone you are standing in. Zones with two activities
(Yuhtunga and Yhoator Jungle) get a section for each.

```
Items Collected - 241   Last Skill Up - 12
```

**Items Collected** is everything logged in this zone, and it survives resets
so your drop percentages stay meaningful. **Last Skill Up** is how many swings
ago it was, failures and broken tools included, and it carries across zones
because your skill does.

It reads **Cap (20)** once your skill reaches the zone's ceiling, naming the
cap, since the count is then measuring a drought the zone cannot end. Only a
few zones have a known cap; the rest show the count regardless.

Fatigue bar colours:

| Colour | Fatigue |
|---|---|
| Light blue | 0 to 149 |
| Yellow | 150 to 199 |
| Red | 200, fatigued |

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
Ashita/config/addons/HELMdiel/<Character>_export.csv
```

One row per item per zone, with that zone's drop rate, fatigue and counters
alongside, which drops straight into a pivot table.

**Minimum Data**, the checkbox under it, cuts the export down to Activity,
Zone, Item, Count, Zone Gathers and Drop Rate. Your character name, fatigue,
attempts, successes, skill ups and skill level are all left out, so you can
share your drop data without attaching who you are or how you play. It is the
half most people want anyway.

Your name comes off the filename too, so a minimal export writes
`HELMdiel_export.csv`. That name is fixed, so it overwrites the last one
whichever character made it.

Two reset buttons:

- **Reset Gather/Skill Ups** clears the Home counters and the Spoils tab. Your
  fatigue, drop history and skill levels are kept. This starts a new session.
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

- **Skill up rates depend on your skill against a zone's cap**, which HELMdiel
  does not model. Rates recorded at different skill levels are not comparable,
  and a zone that looks slow may just be a poor match for your current skill.
- Zone IDs use standard retail-compatible numbering and have not been checked
  one by one against HorizonXI's server.
- The rule that a gather decays *all* other zones, rather than only the most
  recently fatigued, was inferred from a two-zone observation.

## Feedback

Corrections to the message patterns and zone lists are the most useful thing
you can send, and `/helmdiel debug` output is ideal.

Open an issue at
[github.com/KisamMeow/HELMdiel/issues](https://github.com/KisamMeow/HELMdiel/issues),
or DM me on Discord. I am Masuru in HorizonXI.

## Credits

Written by Masuru for HorizonXI. Thanks to the Ashita development community.

## License

HELMdiel is free software, released under the GNU General Public License,
version 3. See [LICENSE](LICENSE) for the full text.

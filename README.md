# HHelmet

Tracks HorizonXI's new HELM system released in 2.0.0

This addon is in very early development, there will be bugs and the UI will be reworked as I get closer to being feature complete.

Ashita v4.30+ addon. Version 0.7.1. Released under GPL-3.0. Coded with help from Claude Opus 5.

## Features

- A Home tab showing everything relevant to the zone you're standing in,
  including zones that support more than one HELM activity.
- Per-zone fatigue counters for each of the four HELM activities, tracked
  independently and persisted per character.
- Skill levels, read automatically from your skill-up messages.
- Attempt, success, and skill-up counts per zone, so you can see what a zone is
  actually costing you.
- A Settings tab for your skill levels and the addon's options, including
  hiding any activities you don't work and a minimum mode for the Home tab.
- Item names shown the way your inventory shows them, not the way the chat log
  writes them.
- Colored progress bars showing how close each zone is to the 200 cap.
- Automatic detection from the chat log, with no manual counting.
- Item drop logging per zone, grouped into rarity tiers, for eyeballing rough
  drop rates.
- Optional auto-open: the window pops up when you gather.

## Coming soon

Planned, in no particular order and with no promised timeline:

- Export gathered data to a CSV file, openable in Excel or Sheets
- UI rework
- Rank tracking

## Installation

**Requires Ashita v4.30 or newer.**

Download from [github.com/KisamMeow/HHelmet](https://github.com/KisamMeow/HHelmet)
and copy the `HHelmet` folder into your Ashita `addons` directory, then load it:

```
/addon load HHelmet
```

To load it automatically, add that line to your Ashita script (usually
`Ashita/scripts/default.txt`).

## Commands

  * **/hhelmet** - _Toggles the fatigue window._
  * **/hhelmet show** / **/hhelmet hide** - _Shows or hides the window._
  * **/hhelmet debug** - _Toggles printing of raw incoming chat lines, used to
    calibrate message detection (see below)._
  * **/hhelmet reset all** - _Wipes everything for the current character,
    gathered items included. Same as the Reset All Data button._
  * **/hhelmet reset &lt;activity&gt;** - _Wipes one activity across all zones._
  * **/hhelmet reset &lt;activity&gt; zone** - _Wipes one activity in the current
    zone only._
  * **/hhelmet set &lt;activity&gt; &lt;0-200&gt;** - _Manually sets the current zone's
    fatigue for one activity. Useful for seeding the counter when you start
    using the addon partway through a session._
  * **/hhelmet skill &lt;activity&gt; &lt;value&gt;** - _Manually sets your skill level
    for one activity. The Settings tab does the same thing with a box._

## How fatigue works

Each activity has its own fatigue counter **per zone**, capped at 200.

- A successful gather in your current zone raises that zone's counter by 1.
- That same gather lowers every **other** tracked zone's counter for that
  activity by 1.
- At 200 the zone is fatigued: You will no longer be able to gather any items
  in that zone until you reduce fatigue by doing the same HELM activity in
  another zone.

So if Giddeus is capped at 200 and you go harvest 100 times in West
Sarutabaruta, Giddeus falls to 100.

The counters are a model of the server's behavior built from observed play,
not a readout of the server's actual numbers. Treat them as a close estimate.
If you gather without the addon loaded, or on a character you've just started
tracking, use `/hhelmet set` to bring the counter back in line.

**The game itself corrects the drift.** When it tells you a zone is tapped out,
HHelmet marks that zone fatigued and sets every other zone for that activity
back to zero. That is what capping a zone from empty would have done anyway,
since it takes 200 gathers there and each one decays the others, so a wrong
count repairs itself the first time you work a zone to the cap.

For the same reason, the red **FATIGUED** label only appears once the game has
actually said so. A counter sitting at 200 is not proof on its own, because it
may have drifted while the addon was unloaded.

## Reading the window

The **Home** tab shows only what applies to the zone you're currently in: your
skill, that zone's fatigue, and what you've gathered there. A few zones support
two activities (Yuhtunga Jungle and Yhoator Jungle are both Harvesting and
Logging), and Home shows a section for each. In a zone with no HELM activity,
it says so.

Home also counts your attempts and skill ups in that zone:

```
Gathers - 24/28 (85.7%)
Skill Ups - 2/28 (7.1%)
Items  -  240 logged
```

**Gathers** is how many attempts gave you an item, out of how many you made,
with your success rate. Failed attempts count, and so does breaking your tool,
because both still cost you time and both can still skill you up.

**Skill ups** is how many you have earned in this zone, against the same
attempt count, with the share of attempts that produced one. Every skill up
counts as one, whether it raised your skill by 0.1 or 0.3.

**Items** is the size of the drop sample below it, which is a different number:
it keeps counting across resets so your drop percentages stay meaningful, while
the gather counters describe effort since counting began.

All of it is per zone. Be careful comparing one zone against another, though:
your skill level relative to a zone's skill cap affects how often you skill up
there, and HHelmet does not account for that yet. See Known limitations.

The next four tabs are one per activity, showing your skill for that activity
at the top, then the zones you have fatigue in. Zones sitting at zero are left
out, so the list stays short until you have actually worked somewhere.

**Settings** is last, and holds **Home Minimum Mode**, a checkbox per activity,
a box for each skill level, the auto-open toggle, and two reset buttons.

**Home Minimum Mode** strips Home back to just your skill and the current
zone's fatigue, dropping the Gathers and Skill Ups counters and the item list.
Useful if you only want to watch how close a zone is to being tapped out.
Everything keeps being tracked while it is on, and the activity tabs are
unchanged, so the detail is still there when you want it.

Unchecking an activity removes its tab and drops it from Home, which is useful
if you only work one or two of them. It keeps tracking in the background, so
nothing is lost and re-checking brings everything back.

The two reset buttons:

- **Reset Session** clears only the two Home tab counters, Gathers and Skill
  ups. Your fatigue, gathered items, and skill levels are all kept, so you can
  start a fresh measurement without losing anything you have built up.
- **Reset All Data** clears everything for this character, fatigue and gathered
  items included. `/hhelmet reset all` does the same thing.

Skill starts as `unknown`. The game only reports your skill when it goes *up*,
so an existing level can't be detected. Type it into the Settings tab, or
just wait for your next skill-up and it fills itself in.

Bar colors:

| Color | Fatigue | Meaning |
|---|---|---|
| Light blue | 0–149 | Plenty of headroom |
| Yellow | 150–199 | Approaching the cap |
| Red | 200 | Fatigued |

Below the bars, each zone has a collapsible item log. Open one and it shows how
many gathers it is based on, then what dropped, grouped by how often it
appeared:

| Tier | Share of that zone's gathers |
|---|---|
| Common | 20% or more |
| Uncommon | 10–19% |
| Rare | 5–9% |
| Very Rare | 1–4% |
| Extremely Rare | under 1% |

Items are sorted by how often they drop, most common first. These percentages
are only as good as your sample size. A zone with 20 gathers logged will show
wildly misleading tiers. Give it a few hundred before reading anything into it.

## Detection status

Detection works by matching text in your chat log. **All four activities have
been verified against real HorizonXI messages.**

Excavation and Mining are worth explaining, because the game gives them the
same success message: both say "You successfully dig up." Nothing in the
text distinguishes them, so HHelmet uses the zone you're standing in to tell
them apart. That works because no zone appears in both lists. If you gather
in a zone HHelmet doesn't track, an ambiguous message may be filed under the
wrong activity; the fix is to report the zone so it can be added.

Three messages have not been seen directly yet:

- **Logging's failure message** and **Logging's message for breaking a hatchet
  while still getting a log.** Both match what the older `hgather` addon uses,
  so they are very likely right, but neither has been confirmed here. If
  Logging's success rate sits at a permanent 100%, the failure pattern is wrong
  rather than your luck being remarkable.
- **The fatigue-cap message**, verified for Harvesting only and assumed shared
  by all four.

Reporting the real text for any of these fixes it in one line.

If something isn't being counted:

1. Run `/hhelmet debug`.
2. Gather with the tool in question.
3. Copy the exact lines that appear and report them (see Feedback below).

## Tracked zones

Fatigue and item logging cover a fixed list of zones per activity:

- **Harvesting**: West Sarutabaruta, Giddeus, Yuhtunga Jungle, Yhoator
  Jungle, Bhaflau Thickets, Wajaom Woodlands
- **Excavation**: Attohwa Chasm, Korroloka Tunnel, Maze of Shakhrami,
  Tahrongi Canyon
- **Logging**: Buburimu Peninsula, Carpenters' Landing, East Ronfaure,
  Ghelsba Outpost, Jugner Forest, Lufaise Meadows, Misareaux Coast, Yhoator
  Jungle, Yuhtunga Jungle, Caedarva Mire, Mamook
- **Mining**: Gusgen Mines, Ifrit's Cauldron, Newton Movalpolos, Oldton
  Movalpolos, Palborough Mines, Yughott Grotto, Zeruhn Mines

Gathering in a zone outside these lists still updates fatigue for that zone,
but it won't appear in the window and its drops aren't logged.

## Data

Everything is stored per character at:

```
Ashita/config/addons/HHelmet/<Character>_<id>/settings.lua
```

Deleting that file resets the character completely, same as `/hhelmet reset all`.

## Known limitations

- Skill up rates are affected by your skill level against a zone's skill cap,
  and HHelmet does not account for that. You can still skill up in a high cap
  zone at low skill, but the rate is heavily reduced, and your rate anywhere
  drifts as you level. Numbers collected at different skill levels are not
  directly comparable, and a zone that looks slow may just be a poor match for
  your current skill.
- The fatigue-cap message is confirmed only for Harvesting.
- Two of Logging's messages have not been seen directly, its failure and the
  one for breaking a hatchet while still getting a log. Both match what an
  older gathering addon uses, so they are probably right, but if either is
  wrong those cases go uncounted.
- Excavation and Mining share a success message and are separated by zone,
  so gathering either one in an untracked zone can be misfiled (see above).
- Zone IDs use the standard retail-compatible numbering and have not been
  checked one-by-one against HorizonXI's server.
- The rule that a gather decays *all* other zones, rather than only the most
  recently fatigued one, was inferred from a two-zone observation and hasn't
  been stress-tested against three or more fatigued zones at once.
- Logged item names keep their leading article, e.g. `a sprig of dyer's woad`.

## Feedback

Corrections to the message patterns and zone lists are the most useful thing
you can send. Debug output from `/hhelmet debug` is ideal.

Open an issue at
[github.com/KisamMeow/HHelmet/issues](https://github.com/KisamMeow/HHelmet/issues).

Or you can DM me on Discord, I am Masuru in HorizonXI.

## Credits

Written by Masuru for HorizonXI. Thanks to the Ashita development community.

## License

HHelmet is free software, released under the GNU General Public License,
version 3. See [LICENSE](LICENSE) for the full text.

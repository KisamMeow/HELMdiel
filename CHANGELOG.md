# Changelog

All notable changes to HELMdiel are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Read this before you trust the Gil/hr inside a zone's foldout

> [!WARNING]
> **This is about the `GIL/HR` inside each zone's foldout on an activity tab
> — not the Gil/hr tile on Spoils, which is unchanged and still correct.**
> If you were already using HELMdiel, every *zone's* `GIL/HR` reads `-` when
> you update, and keeps reading `-` until you have put 190 timed gathers into
> that zone. Nothing is broken: the figure needs a clock that did not exist before
> 0.23.0, and no amount of past data can supply it.

**Which number this is about.** Open an activity tab, open a zone, and the new
line under its skills reads `GIL/HR` and `PER GATHER`. Spoils' own Gil/hr tile
answers a different question — what this *session* has paid an hour, across
every zone — and it has had a working clock since 0.11.0. Nothing below applies
to it.

**Your drop history has no timing in it.** HELMdiel has always recorded *what*
you gathered and *where*, never *when*, so there is nothing to reconstruct a
per-zone rate from. A zone with ten thousand recorded gathers starts with zero
recorded seconds, the same as a zone you have never set foot in.

**So every zone shows `-` until it has timed 190 gathers of its own**, a
fatigue cap with room to spare — the first gather of every visit opens an
interval and times nothing, so a full 200 run never yields 200 timed.
Nothing is borrowed from how fast you gather elsewhere
to fill the gap: a borrowed figure moves when you gather *anywhere* — cut logs
in Yhoator and the number sitting on Attohwa Chasm shifts — which is the fault
the whole per-zone clock exists to remove.

**Hover the figure to see which of the two readings you are on:**

| The hover says | What it means |
|---|---|
| `N an hour, … timed here` | Measured in this zone, over the span it names. Trust it. |
| `N of 190 gathers timed here` | Still filling; the rate shows `-`. |

**`PER GATHER` is right immediately and `GIL/HR` is not there yet.** The gil
half is measured from the day you install — your log, your prices, your broken
tools. Only the conversion into an hour ever needed a clock. If you want one
number to compare zones with today, that is the one.

**Both figures are only as good as the prices you have entered**, under
`Edit Prices` on the Spoils tab. A zone with nothing priced shows neither
figure rather than showing zero, because a missing price only means nobody has
checked one yet.

**Do not reset anything to fix this.** `Reset All Data` would clear the drop
history that makes the figure worth having, to correct something that corrects
itself once you have put a proper shift into each zone.

## [Unreleased]

## [0.27.0] - 2026-09-30

### Added

- **Aluminum Ore in Newton Movalpolos**, from skill 40.
- **Pigeon's Blood in Aydeewa Subterrane**, from skill 60.
- **Siren's Hair in Arrapago Reef**, from skill 60.
- **Jadeite and Avatar Blood in Aydeewa Subterrane**, from skill 30.
- **Import Starter Prices in Edit Prices**, a starting set of prices and
  Vendor marks, either replacing yours or filling only the items still at 0.

### Changed

- **Grain Seeds, Vegetable Seeds, Petrified Log, Green Rock and Yellow Rock
  are no longer greyed in Edit Prices.** Each shows once, under the activity
  that drops it.
- **Rotting Timber is reported to stop 4.9 below a zone's cap**, not 5, so in
  a zone capped at 20 it stops at 15.1 rather than 15.
- **Platinum Ore needs skill 40 in Oldton Movalpolos and 30 in Newton
  Movalpolos.**

### Removed

- **Plumbago, Little Worm and Dragon Fruit from the price list.** All three
  were listed on the wiki as HELM drops but are not.

## [0.26.0] - 2026-09-29

### Added

- **The second-best zone on each activity tab is named in light blue**, beside
  the gold of the best.

### Changed

- **The bracketed zone `GIL/HR` is every drop sold to an NPC**, counting
  auction house items at their NPC price, rather than only the items ticked
  Vendor.
- **Optimization pass.** Edit Prices in particular does far less work each
  frame; nothing looks different.

### Fixed

- **Exported CSVs end each line once.** Every line carried a stray extra
  carriage return.
- **An item two activities drop has one price.** Its second box in Edit Prices
  was saved but never used; both boxes now show and set the same price.
- **A fatigue bar stops at its end** when a lowered skill level leaves a zone
  above its cap.
- **`/hd set` stores a whole number and reports what it stored**, after the
  cap, rather than what was typed.

## [0.25.0] - 2026-09-27

### Added

- **Khroma Ore in Mount Zhayolm and Luminium Ore in Halvung**, both from
  skill 50.
- **Thirteen drops in Aydeewa Subterrane**, which listed only Phil. Stone
  before.
- **The best-earning zone on each activity tab is named in gold**, with its
  gil an hour on the hover. It needs at least two zones with a timed rate to
  compare.

### Changed

- **The vendor floor shows beside `GIL/HR` in brackets**, as
  `19,179 (16,728)`, rather than in the hover, so zones can be compared by it
  at a glance.

### Removed

- **Mine Gravel and Wyvern Egg from the price list.** Both were listed on the
  wiki as HELM drops but are not.

## [0.24.0] - 2026-09-26

### Added

- **The `Vendor` box now also says what kind of price you typed**, and every
  item starts ticked. Untick it where the price is an auction house one, and
  a zone's hourly rate names the vendor floor underneath it — the part you
  could carry to an NPC today without waiting for a sale.
- **A zone's hover values a full fatigue run**, at its real ceiling rather
  than a flat 200, so you can see what one trip there is worth before you
  make it.
- **The hover says how much of the zone is timed**, so a rate measured over
  recent gathers against a much older drop history declares itself.

### Changed

- **Every hover is shorter.** Same facts, fewer words — the worst of them was
  five lines and is now four. `GIL/HR` leads with the rate rather than the
  per-gather figure, since that is what the label promises.
- **The rate warns when node repeats are left out of your drop counts**, which
  makes it run a little high. Only on Mining zones where a node has actually
  repeated, and only while the box is unticked.
- **`Hide Vendor Items` now hides everything on a fresh file**, since every
  item counts as vendor until you untick it. Untick the ones you sell
  yourself and it becomes a way to show only those. Any Vendor marks from
  before this version are ignored rather than guessed at.

## [0.23.2] - 2026-09-26

### Fixed

- **Working two activities in one zone no longer stops the clock entirely.**
  Yhoator and Yuhtunga are both Harvesting and Logging, and a rotation that
  alternated them timed nothing at all — both tabs showed `-` however long you
  worked the zone. Each gap now goes to whichever tool ended it, so the two
  split the time without losing any of it.

### Changed

- **A zone needs 190 timed gathers for its hourly figure, not 200.** The first
  gather of every visit opens an interval and times nothing, so a full
  200-gather fatigue run yields at most 199 timed and every re-entry costs
  another — at 200 no zone could ever qualify on a single run.

## [0.23.1] - 2026-09-26

### Added

- **Rotting Timber's hover says where it stops.** It is reported to stop
  firing within 5 skill of a zone's cap, so the tooltip names that level for
  the zone you are in, or says you are already past it. Reported from play
  rather than confirmed, so nothing else acts on it.

### Changed

- **The idle cutoff is twelve minutes, down from fifteen.** A gap longer than
  that between two gathers still counts as time away rather than time
  gathering, so both Spoils' Gil/hr and every zone's own figure rise a little.
- **A zone's `GIL/HR` comes from that zone's clock or from nothing.** It no
  longer falls back to how fast you gather elsewhere, so it reads `-` until
  the zone has timed 200 gathers of its own and the hover counts you in
  towards them. A borrowed figure moved when you gathered in another zone,
  which is the fault the per-zone clock exists to fix.

### Fixed

- **`GIL/HR` no longer quotes a rate built from two gathers after a reset.**
  The fallback had no minimum at all: two gathers four seconds apart read as
  1,800 an hour, and every zone on the tab was multiplied by it.

## [0.23.0] - 2026-09-25

### Added

- **What a zone earns, inside its foldout on an activity tab.** `PER GATHER`
  is its whole drop history at today's prices, less the tools that broke
  there; `GIL/HR` is that figure at the pace you gather it.
- **Each zone now times itself**, so its hourly figure stops moving when you
  gather somewhere else. The clock counts the gap between two gathers in the
  same zone, pauses when you leave and past twelve minutes idle, and a zone
  falls back to your overall pace until 200 of its gathers are timed. The
  hover says which reading you are looking at.
- **Turtle Shell in Korroloka Tunnel.**

## [0.22.0] - 2026-09-20

### Added

- **A Rotting Timber tile for Logging**, with its rate on Home and on the
  Logging tab, and a `Rotting Rate` column in the export. Each one counts as
  a lost item towards Items Collected, so a zone's drop rates are shares of
  everything the swings took, rotten included. Spoils lists how many were
  lost, at no gil.

### Changed

- **Spoils scrolls past twenty items** instead of growing the window. The
  headings and the tool rows stay in place.

### Fixed

- **Maze of Shakhrami does not drop Bone Chip or Chicken Bone.** Both were
  listed from the wiki and neither has turned up in play.
- **Arrapago Reef's Rock Salt was listed under a second spelling**, `Chunk of
  Rock Salt`, which gave it two rows in the price editor.
- **Giddeus's Phoenix Feather needs harvesting 40**, not 30, and **Shall Shell
  in Korroloka Tunnel, Cactus Stems and Antlion Jaw in Attohwa Chasm are not
  gated** — all three were listed at a level.
- **Every Gold Rush and Motherlode ore is on its zone's drop list**, so the
  grid shows it. Eight were missing — Gold, Platinum, Darksteel, Adaman and
  Orichalcum Ore across six zones — and go in without a skill level until one
  is known.

## [0.21.0] - 2026-09-15

### Added

- **What Gold Rush and Motherlode give in each Mining zone.** The two tiles
  name their ore under the rate, the Mining tab shows it beside the rate, and
  those ores carry a gold corner on their icon in the drop grid. Their
  percentages draw in gold while Count Gold Rush/Motherlode Drops is on.
- **Oak Log in Carpenters' Landing** at logging 10, and **Rosewood Log in
  Yuhtunga Jungle** at logging 20.

### Changed

- **Count Gold Rush Drops is now Count Gold Rush/Motherlode Drops.** Motherlode
  upgrades what a Gold Rush node repeats, so its ore is part of the same run
  and the setting covers both.
- **Flipping that setting updates your rates at once**, on Home, the activity
  tabs and the export. It used to apply only to gathers made after the change.
  The first time you untick it after updating, Home's session figures will
  not move until your next session reset; everything else moves straight
  away. An item whose every gather came from a node leaves the grid rather
  than showing 0.0%.
- **On the activity tabs each special skill has its own line** under the
  zone's counts, which brings a Mining zone's foldout back to the width of its
  drop grid.

## [0.20.0] - 2026-09-14

### Added

- **Drop lists for Halvung, Mount Zhayolm, Newton Movalpolos and Ifrit's
  Cauldron** — twelve, twelve, eight and eight items. **Every tracked zone has
  a drop list now.**
- **Ten items are confirmed drops now rather than wiki listings** — Aht
  Urhgan Brass, Bomb Arm, Bomb Ash, Demon Horn, Iron Sand, Moblin Mask,
  Orpiment, Sulfur, Troll Pauldron and Troll Vambrace.
- **Skill levels for five mining drops** — Darksteel Ore at 20 and Gold and
  Mythril Ore at 10 in Oldton Movalpolos, Mythril Ore at 10 in Palborough
  Mines, and Darksteel Ore at 10 in Gusgen Mines.
- **Special skill activation rates in the CSV export**, one column per
  ability, per zone — the same percentages the activity tabs show.

### Changed

- **Reset All Data keeps your skill levels.** Nothing resets them now.

### Fixed

- **Ghelsba Outpost's Elm Log is not gated.** It was listed as needing logging
  10.

## [0.19.0] - 2026-09-10

### Added

- **Jugner Forest's logging cap is 20**, the last one that was missing. **Every
  tracked zone now has a skill cap**, so the raised fatigue ceiling applies
  everywhere.
- **Group by Rarity**, in Settings. Turn it off and a zone's items run
  together in one list ordered by drop rate, with no gaps between the rarity
  tiers. Names keep their tier colour either way.
- **Drop lists for five more logging zones** — Mamook, Lufaise Meadows,
  Carpenters' Landing, Yhoator Jungle and Yuhtunga Jungle — plus nine more
  items across zones that already had one.
- **Thirteen more items have a skill level**, all logging.
- **Seven items are confirmed drops now rather than wiki listings** — Beehive
  Chip, Kitron, Lqr. Tree Sap, Mahogany Log, Persikos, Rattan Lumber and
  Revival Root.

### Changed

- **List Item Style is now 2 Column Style, and puts two items on a row**
  rather than one, which roughly halves how tall a well-worked zone gets.
- **Locked items sort by skill level**, lowest first, so the next one you can
  reach is at the top of the block rather than wherever the alphabet put it.

### Fixed

- **East Ronfaure's Elm Log needs logging 10**, not 5.
- **Opening Spoils on a character that had never gathered unloaded the
  addon.** Switching character threw away some of the settings the tab
  needed.

## [0.18.0] - 2026-09-08

### Added

- **Six more logging skill caps** — Carpenters' Landing 10, Buburimu Peninsula
  and Yuhtunga Jungle 20, Lufaise Meadows, Misareaux Coast and Yhoator Jungle
  40. Those zones now hold more fatigue once you have outskilled them, and the
  activity tab orders them by cap. **Jugner Forest is the only zone left with
  no known cap.**
- **A first drop list for Arrapago Reef** — seventeen items, five of them
  behind a skill level. **Excavation now has a list for every zone it tracks.**
- **Aydeewa Subterrane drops a Philosopher's Stone** at excavation 40.
- **Darksteel Ore in Yughott Grotto** at mining 20, and **Zinc Ore and
  Darksteel Ore in Oldton Movalpolos**.

### Changed

- **Maze of Shakhrami's Petrified Log needs excavation 20**, not 10.
- **A zone's cap chip is the only thing on the right of its foldout now**, so
  the chips line up down the tab. The item count moved inside, onto the zone's
  own line beside the skill up and special skill rates.
- **A zone you have gathered nothing in shows its name dimmed**, which is what
  tells you at a glance whether a collapsed foldout has anything in it.
- **An optimization pass over the render path.** Nothing looks different; the
  activity tab just does less work per frame.

### Fixed

- **Yuhtunga Jungle's logging cap is 20, not harvesting's 40.** It was pulled
  in 0.16.0 for looking wrong, and it was.

## [0.17.0] - 2026-09-06

### Added

- **Export Session**, on the Spoils tab between Edit Prices and Reset Session.
  Writes exactly what that reset clears: the session tally with its gil, and
  the tools it cost, as negative rows at the foot.

### Changed

- **The CSV names its windows.** `Attempts`, `Successes` and `Skill Ups` are
  now `(Session)`, since they reset with Reset Gather/Skill Ups while `Zone
  Gathers` beside them does not.
- **Reset Spoils Session is now Reset Session.**
- **The Opacity slider is wider**, and far easier to aim with.

### Removed

- **The `Fatigue` column** from the CSV. It is a live counter rather than a
  measurement, and says nothing a spreadsheet can use.

### Fixed

- **`/helmdiel reset <activity>` left zones reading FATIGUED** at a counter of
  zero. It cleared the counters but not the flags.

## [0.16.0] - 2026-09-06

### Added

- **Every zone foldout shows its skill cap**, on a chip beside the name. It
  lights up within 20 skill of the cap, marking the zones worth gathering in
  for skill, and turns gold once you have passed it. An activity you have
  never skilled lights its starter zones straight away.
- **Mining skill caps are complete** — Gusgen 20, Ifrit's Cauldron, Newton and
  Oldton 40.

### Removed

- **Yuhtunga and Yhoator's logging caps**, which look unreliable. Harvesting's
  caps for the same two zones are unchanged.

### Changed

- **A zone foldout is two lines instead of three.** The item count moved up
  beside the cap, and the skill up and special skill rates share one line.
- **An outskilled zone drops its skill up rate**, since it can no longer move.
- **A rule separates a zone's figures from its drops.**
- **Zones are listed by skill cap**, lowest first, then alphabetically. Zones
  whose cap is not known yet sit at the bottom.
- **The Last Skill hover is one line**, and its skill up rate now carries two
  decimals.

## [0.15.1] - 2026-09-02

### Fixed

- **Home's middle tile is captioned `LAST SKILL`**, which fits. `LAST SKILL UP`
  was clipped at the narrowest window.

## [0.15.0] - 2026-09-02

### Removed

- **Skill ups by moon phase.** A 40-to-50 harvesting run gave 9,562 swings
  across all eight phases and showed no effect, which is what the tile was
  added to find out.

### Changed

- **Home's middle tile is Last Skill Up again**, showing swings since your
  skill last rose. Hover it for the rate.
- **Spoils leads with Gil/hr.** Hover it for what you gathered, what the tools
  cost, and how long you have been at it.
- **The session clock only counts time you were gathering.** A gap of more
  than fifteen minutes is not counted, and logging out, `/shutdown`, a crash or
  a disconnect all stop it.

### Fixed

- **Yughott Grotto caps mining skill at 10, not 20.** Past skill 10 there, your
  fatigue counter stopped at 200 when the real ceiling was 250, so gathering
  looked like it had stopped counting.
- **A negative gil figure could render as `-,495`.** Net Gil, Lifetime and the
  Gil/hr rate all go negative when broken tools outrun what you gathered.

## [0.14.3] - 2026-08-31

### Added

- **Broken tools are listed at the foot of Spoils**, under a rule, with what
  they cost you in red.

### Changed

- **The Lifetime Gil tooltip is two lines** instead of six.
- **Auto-Open on Gather explains itself**, like the settings around it.

### Fixed

- **The Opacity hint** no longer mentions a title bar the window has not had
  since 0.14.2.

## [0.14.2] - 2026-08-30

### Changed

- **The title bar is gone.** Drag the window by the nav row and close it with
  the `×` at the right-hand end.
- **Rounder corners** on the window and on everything drawn inside it.
- **The nav row reads as one segmented control**, with the buttons inset into
  the track and the selected one on the same surface as a stat tile.
- **Shorter activity tabs** — Harv, Exca, Logg and Mine — so the row takes less
  width.
- **Uniform capitalisation** on the Tracking settings.

### Added

- **Auto-Show Activity**, off by default. With it on, gathering an item from a
  hidden activity brings its tab back.

## [0.14.1] - 2026-08-28

### Added

- **Arrapago Reef and Aydeewa Subterrane** are tracked for excavation, both
  capped at 60. Added to HorizonXI in today's patch; no drop lists for them
  yet, so they show what you find there.
- **Eight more known drops**, including a first list for Caedarva Mire, plus
  skill gates for Emerald and Green Rock in Attohwa Chasm.

## [0.14.0] - 2026-08-28

### Added

- **Skill ups by moon phase.** The Skill Ups tile reads `MOON 31%`, how lit
  the moon is, over your skill up rate under that phase; hover it for all
  eight. Pooled across zones, since eight phases split the data thin.
  **This one may not stay.** Nobody has shown the moon affects HELM skill ups
  at all — the tile is here so we can find out, and it goes if it turns out to
  make no difference.
- **Skill caps for fourteen more zones**, so their fatigue bars now rise past
  200 once you outskill them. Every harvesting and excavation zone is covered;
  nine logging and mining zones are still unknown.

### Changed

- **Spoils is summarised by two tiles**, Net Gil and Lifetime, sat under Hide
  Vendor Items rather than four lines of text at the foot. Hover Net Gil for
  what it is made of and your gil an hour, and Lifetime for a note that it
  moves as you adjust prices.
- **Swings in a zone you have outskilled no longer count** towards the swings
  since your last skill up, since that zone could never have given you one.
  Everything else about those swings is recorded as before.
- **The Skill Ups hover is shorter and plainer**, whichever of the three things
  it is showing you.

### Fixed

- **Home draws a line under the skill**, the way the activity tabs do.

## [0.13.0] - 2026-08-26

### Changed

- **Home's item tracking is per session now.** Items Collected and the drop
  percentages under it cover the current spoils session, and a reset clears
  them. The activity tabs keep the full history, which is where drop rates
  worth trusting live.

### Added

- **Lifetime gil at the bottom of Spoils**, everything this character has ever
  gathered less every tool it has broken. Only Reset All Data clears it.

### Fixed

- **Tools no longer offer a Vendor tick box.** It did nothing, since a tool is
  never something you carry home.

## [0.12.0] - 2026-08-26

### Added

- **A font picker**, at the top of Settings: Segoe UI, Consolas, Arial, Tahoma
  or Trebuchet MS.
- **A Vendor tick box per item** in Edit Prices, for things you just sell to an
  NPC. Marked items read grey in Spoils.
- **Hide Vendor Items** on the Spoils tab drops them from the list. They still
  count towards the total.
- **Halvung and Mount Zhayolm** are tracked for Mining, with their wiki-listed
  legacy items.
- **Tools are priced too.** Edit Prices has a Tools block for the sickle,
  pickaxe and hatchet.
- **Tools Broken on Spoils**, totalling what this session's broken tools cost
  to replace.

### Changed

- **Spoils sorts by gil**, highest earner first, instead of by name.
- **The Spoils list reads white**, with grey now reserved for vendor items.
- **Total is now Net Gil**, with broken tools deducted, and Per Hour divides
  the net.
- **The activity tabs show the skill the way Home does**, as a caption and a
  right-aligned value.
- **Gold Rush now tracks the node itself** rather than guessing from the item
  name, so walking to another vein that gives the same ore is no longer read
  as the same run, and a miss no longer ends one early.
- **Moblin Mail is a known Oldton Movalpolos drop** instead of an unconfirmed
  wiki listing.
- **Skill Ups and Last Skill are one tile.** It shows the rate, or Cap (20)
  once your skill reaches the zone's ceiling. Hover it for the skill ups, the
  swings behind them, and how long since the last one.
- **Each special skill has its own tile** where Last Skill used to be, showing
  its activation rate. Hover one for its full name and the count behind it;
  Gold Rush also lists what its nodes gave you.
- **The README is shorter**, and carries a Thanks section crediting the addons
  HELMdiel learned its technique from.

### Fixed

- **Moblin Armor and Moblin Mail** showed under the wording the chat log uses
  rather than their inventory names, which also left Moblin Armor listed twice:
  once at its real rate and once as never seen.

## [0.11.1] - 2026-08-25

### Added

- **Lots of new known drops**, mostly Excavation's skill-gated items and the
  whole of Oldton Movalpolos for Mining.
- **Legacy items in the price list.** Items the HorizonXI wiki lists as HELM
  drops that this addon has never seen are there to be priced, dimmed and
  marked as unconfirmed. Not done for Harvesting.

### Changed

- **The window is a charcoal surface with a hairline border**, instead of pure
  black, so it holds an edge against a bright zone.
- **The title bar is a shade lighter than the body**, and still follows the
  opacity slider.
- **Every control is themed.** Checkboxes, sliders, input boxes, dropdowns,
  dividers and the price editor's scrollbar were still on Ashita's default
  theme, which is why a red scrollbar showed up in the price list.
- **Your character name is in the window title now**, so the line under the
  title bar and the rule below it are gone.
- **Settings blocks are named** rather than just ruled apart.
- **Spoils column headings and the "nothing here yet" lines** take the same
  quiet caption styling as the counters on Home.
- **The window will not shrink narrower than its nav row.**
- **Home Minimum Mode is now a Home Detail dropdown**: Full, Normal or Compact.
  Normal is new, and drops just the item list.
- **Checkboxes fill rather than tick**, matching the rest of the window.
- **Item Size and Item Style are tick boxes now**, Large Item Size and List Item
  Style. Your existing choice is kept either way.
- **The dropdowns are wide enough for their longest option**, so Compact no
  longer reads as "Compa".

### Fixed

- **Three item names corrected** to their inventory spellings: Goblin Die,
  Moblin Armor and H.Q. Scp. Shell.

## [0.11.0] - 2026-08-23

### Added

- **Gil per hour on the Spoils tab**, under the total. It is measured from your
  first gather to your last, so an idle window does not drag it down, and every
  reset that clears the tally restarts it.
- **Count Gold Rush Drops in Settings.** A Gold Rush node repeats one item until
  it runs out; turning this off keeps those repeats out of your drop rates. On
  by default, and they always count towards Spoils either way.
- **Hovering the Gold Rush figure** lists what came from Gold Rush nodes in that
  zone, and says whether they are being counted.

### Changed

- **The window has had a visual pass.** Nothing it tracks or counts has moved.
- **The nav buttons sit in a track**, so the row reads as one control.
- **The window sizes itself to its contents again**, instead of staying as wide
  as the widest tab you last visited.
- **Home's counters are three tiles**, replacing the counter line. They stretch
  with the window like the fatigue bar does.
- **The fatigue bar is a slim track under its label**, so the coloured block is
  much smaller and no text sits on top of it.
- **Rarity is the item name's colour**, and the coloured border around each
  icon is gone, so the art now fills its box.
- **Settings help text moved into tooltips**, halving the panel's height.
- **Body text is a neutral grey**, leaving gold as an accent only.
- **Icon Size is now called Item Size**, since it sizes the item text as well.
- **The reset buttons take two clicks.** The first arms the button and it asks
  to be clicked again; it disarms itself after a few seconds.

## [0.10.2] - 2026-08-23

### Added

- **Lots of new known drops**, mostly to logging.

### Fixed

- **Fresh Mugwort in Bhaflau Thickets needs skill 20, not 30.**

## [0.10.1] - 2026-08-19

### Fixed

- **Phalaenopsis no longer shows as a Yhoator Jungle drop.** It does not drop
  there on current information; Yuhtunga Jungle is unaffected.

## [0.10.0] - 2026-08-19

### Added

- **Items a zone is known to drop are now listed**, not just the ones you have
  found. Unfound items sit in grey below the rest: **Not seen** if you can
  gather it, **Locked (10)** if you need that skill level first. Gathering one
  moves it up with its own percentage.
- **A profit column on the Spoils tab** under Item / Amount / Gil headings,
  your count times the price you set, with a session total under it.
- **Edit Prices on the Spoils tab**, every gatherable item split by activity,
  with a box to type what it sells for. Prices save as you type, are shared by
  every character, and no reset clears them. 86 items ship listed.
- **`/helmdiel names`** reports any tracked item whose name does not match what
  your game calls it, so it can be corrected.

## [0.9.8] - 2026-08-19

### Added

- **Zones you have outskilled hold more fatigue**, 50 more for every 10 skill
  levels above the zone's cap. The bar and its colours follow the raised number.
- **Special skill rates on the activity tabs**, inside each zone's foldout
  under its skill up rate, so you can compare zones without walking to them.

### Fixed

- **Swings at a zone you have already capped no longer count**, since you
  cannot skill up while fatigued and counting them dragged down your skill up
  rate and inflated Last Skill Up.

### Changed

- **Only the three chat modes the game actually uses for HELM messages are
  read now**, so nothing anyone types in any channel can move your counters.
- **`/helmdiel debug` shows every line**, including the ones dropped by that
  filter, marked `dropped` and named by mode.

## [0.9.7] - 2026-08-17

### Added

- **The skill up rate is back on Home**, in light blue on the same line as your
  skill, counted against your swings in the current zone.
- **And inside each zone's foldout** on the activity tabs, against that zone's
  swings.

### Changed

- **Exports are stamped with the date and time**, so they collect beside each
  other in date order instead of overwriting the last one.
- **Home always shows the fatigue bar**, including at zero. Activities you have
  unchecked in Settings still stay hidden.

## [0.9.6] - 2026-08-16

### Added

- **`/hd` as a short alias for `/helmdiel`**, taking the same arguments.
- **Special skill activation rates on Home**, under each activity's skill and
  scoped to the zone you are in: Gatherer's Discipline, Gold Rush and
  Motherlode against the Items Collected figure below them, and Practiced
  Technique against the pickaxes that broke or would have. Logging's are not
  known yet. **If you gathered before 0.9.6, Reset All Data for an accurate
  rate**, after exporting if you want to keep the drop data.

### Fixed

- **Someone typing a gather or skill-up message in chat can no longer move
  your counters.** Anything arriving on a chat channel a player can type on is
  ignored.
- **Breaking a tool is finally counted.** The tool's name is highlighted in
  that message, and the highlighting was hiding it from detection, so every
  broken sickle, pickaxe and hatchet went unrecorded. Your success rate was
  overstated by that much.
- **Tool breaks and special skills are no longer counted more than once.** One
  gather can reach the addon three times; only the first counts.

## [0.9.5] - 2026-08-16

### Changed

- **Minimum Data now keeps your skill level.** A shared drop sample means
  little without the skill it was gathered at.

## [0.9.4] - 2026-08-15

### Fixed

- **The window resizes immediately** when moving from a wide tab to a narrow
  one, instead of creeping down over several seconds. The fatigue bar still
  stretches to the full width.

### Changed

- **Home shows Items Collected and Last Skill Up**, replacing the
  Gathers and Skill Ups rates. Both barely moved, so the space went to figures
  that do. Everything behind them is still tracked and still exported.
- **Last Skill Up reads Cap (20)** once your skill reaches the zone's ceiling.
  Only a few zones have a known cap; the rest show the count as before.
- **Gathers is now Items Collected** on the activity tabs, the same figure
  under a clearer name, and it has moved into each zone's foldout title so a
  closed zone still shows its total.
- **The Item Tracking heading is gone** from the activity tabs.
- **List mode now stacks the drop rate under the item name**, matching Grid.
- **Item names and their drop rates sit closer together**, and the icon and
  its text are centred on each other.
- **Small icons draw the item text two points smaller.**

## [0.9.3] - 2026-08-15

### Fixed

- **Rotting timber is now counted.** It yields nothing but still adds fatigue,
  so it is tracked as an attempt that raises your counter without logging an
  item.

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

[Unreleased]: https://github.com/KisamMeow/HELMdiel/compare/v0.27.0...HEAD
[0.27.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.26.0...v0.27.0
[0.26.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.25.0...v0.26.0
[0.25.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.24.0...v0.25.0
[0.24.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.23.2...v0.24.0
[0.23.2]: https://github.com/KisamMeow/HELMdiel/compare/v0.23.1...v0.23.2
[0.23.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.23.0...v0.23.1
[0.23.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.22.0...v0.23.0
[0.22.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.21.0...v0.22.0
[0.21.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.20.0...v0.21.0
[0.20.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.19.0...v0.20.0
[0.19.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.18.0...v0.19.0
[0.18.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.17.0...v0.18.0
[0.17.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.16.0...v0.17.0
[0.16.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.15.1...v0.16.0
[0.15.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.14.3...v0.15.0
[0.14.3]: https://github.com/KisamMeow/HELMdiel/compare/v0.14.2...v0.14.3
[0.14.2]: https://github.com/KisamMeow/HELMdiel/compare/v0.14.1...v0.14.2
[0.14.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.14.0...v0.14.1
[0.14.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.11.1...v0.12.0
[0.11.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.10.2...v0.11.0
[0.10.2]: https://github.com/KisamMeow/HELMdiel/compare/v0.10.1...v0.10.2
[0.10.1]: https://github.com/KisamMeow/HELMdiel/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.8...v0.10.0
[0.9.8]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.7...v0.9.8
[0.9.7]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.6...v0.9.7
[0.9.6]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.5...v0.9.6
[0.9.5]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.4...v0.9.5
[0.9.4]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.3...v0.9.4
[0.9.3]: https://github.com/KisamMeow/HELMdiel/compare/v0.9.2...v0.9.3
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

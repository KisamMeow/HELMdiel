require('common');

local data = T{};

-- The mechanic
data.FATIGUE_CAP          = 200;
data.FATIGUE_WARN_RATIO   = 0.75;
data.FATIGUE_BONUS_PER    = 10;
data.FATIGUE_BONUS        = 50;
data.DEDUP_WINDOW_SECONDS = 1.0;
data.DEDUP_QUIET_SECONDS  = 0.10;

data.ACTIVITIES = T{ 'Harvesting', 'Excavation', 'Logging', 'Mining' };

-- Chat modes HELM messages have been captured on. Anything on any other mode
-- is somebody talking, never the game reporting a gather.
data.CHAT_MODE_MASK = 256;

data.HELM_CHAT_MODES = T{
    [121] = true,   -- skill ups, the fatigue cap, procs, rotting timber
    [151] = true,   -- gathers, failures and tool breaks, the original line
    [190] = true,   -- the same three, re-emitted with a timestamp
};

-- Nav order
data.NAV_LEADING  = T{ 'Home' };
data.NAV_TRAILING = T{ 'Spoils', 'Settings' };

-- Display only. The tab's identity stays the activity name, so nothing that
-- compares against ACTIVITIES has to know these exist.
data.NAV_SHORT    = T{
    Harvesting = 'Harv',
    Excavation = 'Exca',
    Logging    = 'Logg',
    Mining     = 'Mine',
};

-- Pixel sizes
data.SKILL_INPUT_WIDTH  = 70;
data.COMBO_WIDTH        = 120;
-- The opacity slider is a drag, not a number box, so it wants room: it shared
-- SKILL_INPUT_WIDTH's 70px and gave a hundredth of opacity per pixel, four
-- pixels for a 0.05 step. Wider than the combos and still inside the width the
-- skill row already sets, so Settings does not grow.
data.SLIDER_WIDTH       = 200;
data.CHECK_INSET        = 4.0;
data.CHECK_GAP          = 8.0;
data.PRICE_INPUT_WIDTH  = 90;
data.PRICE_EDITOR_HEIGHT = 320.0;
data.FATIGUE_BAR_HEIGHT = 5.0;
data.ICON_SIZE         = 32;
data.SPOILS_ICON_SIZE  = 16;
data.ITEMS_PER_ROW     = 3;
data.CELL_GUTTER       = 14;
data.NAV_GAP           = 3.0;
data.TILE_PAD_X        = 13.0;
data.TILES_PER_ROW     = 3;
data.TILE_PAD_Y        = 5.0;
data.TILE_GAP          = 5.0;
data.FRAME_ROUNDING    = 7.0;
data.WINDOW_ROUNDING   = 10.0;
data.WINDOW_MIN_WIDTH  = 330.0;
data.TITLE_ALIGN       = { 0.5, 0.5 };

data.FONT_SIZE = 18.0;

data.SMALL_ICON_FONT_DROP = 2.0;
data.ITEM_LINE_GAP        = 1.0;

data.WINDOW_OPACITY = 0.92;
data.OPACITY_MIN    = 0.10;
data.OPACITY_MAX    = 1.00;

-- Surface elevation
data.SURFACE_BASE   = { 0.13, 0.13, 0.17, 1.00 };
data.SURFACE_TITLE  = { 0.19, 0.19, 0.23, 1.00 };
data.SURFACE_RAISED = { 0.22, 0.22, 0.26, 0.90 };
data.SURFACE_PLATE  = { 0.28, 0.28, 0.32, 0.90 };
data.SURFACE_INSET  = { 0.07, 0.07, 0.10, 0.50 };

data.COLOR_EDGE     = { 1.00, 1.00, 1.00, 0.24 };
data.WINDOW_BORDER  = 1.0;
data.SHEEN_HEIGHT   = 90.0;
data.COLOR_SHEEN    = { 1.00, 1.00, 1.00, 0.055 };
data.COLOR_SHEEN_END = { 1.00, 1.00, 1.00, 0.00 };

-- Gold accent, drawn only as the resize grip
data.COLOR_GOLD        = { 1.00, 0.84, 0.20, 1.00 };
data.COLOR_LABEL       = { 0.62, 0.62, 0.67, 1.00 };
data.COLOR_VALUE       = { 0.93, 0.93, 0.96, 1.00 };
data.COLOR_CAPTION     = { 0.48, 0.48, 0.54, 1.00 };
data.COLOR_TILE_BG     = data.SURFACE_PLATE;
data.COLOR_NAV_TRACK   = data.SURFACE_RAISED;
data.COLOR_CHIP        = data.SURFACE_PLATE;
data.COLOR_CHIP_DONE   = { 0.26, 0.22, 0.11, 0.90 };
data.COLOR_NAV_IDLE    = { 0.00, 0.00, 0.00, 0.00 };
data.COLOR_GRIP        = { 1.00, 0.84, 0.20, 0.85 };
data.COLOR_GRIP_HOVER  = { 1.00, 0.90, 0.45, 1.00 };
data.COLOR_GRIP_ACTIVE = { 1.00, 1.00, 0.75, 1.00 };

-- Chrome
data.COLOR_BUTTON        = data.SURFACE_RAISED;
data.COLOR_BUTTON_HOVER  = { 0.32, 0.32, 0.36, 0.95 };
data.COLOR_BUTTON_ACTIVE = { 0.40, 0.40, 0.45, 1.00 };
data.COLOR_NAV_SELECTED  = data.SURFACE_PLATE;
data.COLOR_NAV_HOVER     = { 0.25, 0.25, 0.29, 0.90 };
data.COLOR_NAV_ACTIVE    = data.SURFACE_PLATE;
data.COLOR_HEADER        = { 0.24, 0.24, 0.28, 0.65 };
data.COLOR_HEADER_HOVER  = { 0.32, 0.32, 0.36, 0.85 };
data.COLOR_HEADER_ACTIVE = { 0.38, 0.38, 0.42, 0.95 };

-- Inputs, scrollbars, separators, popups

data.COLOR_INPUT         = data.SURFACE_PLATE;
data.COLOR_INPUT_HOVER   = { 0.34, 0.34, 0.38, 0.95 };
data.COLOR_INPUT_ACTIVE  = { 0.38, 0.38, 0.43, 1.00 };
data.COLOR_GRAB          = { 0.80, 0.80, 0.86, 1.00 };
data.COLOR_GRAB_ACTIVE   = { 0.93, 0.93, 0.97, 1.00 };
data.COLOR_SCROLL_BG     = data.SURFACE_INSET;
data.COLOR_SCROLL        = { 0.36, 0.36, 0.41, 0.85 };
data.COLOR_SCROLL_HOVER  = { 0.44, 0.44, 0.49, 0.95 };
data.COLOR_SCROLL_ACTIVE = { 0.54, 0.54, 0.60, 1.00 };
data.COLOR_SEPARATOR     = { 0.34, 0.34, 0.39, 0.60 };
data.COLOR_POPUP         = { 0.19, 0.19, 0.23, 0.98 };
data.COLOR_TEXT_SELECT   = { 0.36, 0.40, 0.52, 0.60 };

-- Destructive buttons
data.COLOR_DANGER        = { 0.45, 0.16, 0.16, 0.90 };
data.COLOR_DANGER_HOVER  = { 0.60, 0.20, 0.20, 0.95 };
data.COLOR_DANGER_ACTIVE = { 0.72, 0.24, 0.24, 1.00 };

-- Export button
data.COLOR_SUCCESS        = { 0.16, 0.42, 0.20, 0.90 };
data.COLOR_SUCCESS_HOVER  = { 0.22, 0.56, 0.26, 0.95 };
data.COLOR_SUCCESS_ACTIVE = { 0.28, 0.68, 0.32, 1.00 };

-- CSV export columns
-- Three of these reset with Reset Gather/Skill Ups while the rest do not, so
-- the window is named in the column. Zone Gathers is the all-time count and
-- Successes is the same quantity since the last reset; before a reset they are
-- identical, which is exactly why they needed telling apart.
data.EXPORT_HEADER = T{ 'Character', 'Activity', 'Zone', 'Item', 'Count',
                        'Zone Gathers', 'Drop Rate', 'Attempts (Session)',
                        'Successes (Session)', 'Skill Ups (Session)', 'Skill' };

data.EXPORT_HEADER_MIN = T{ 'Activity', 'Zone', 'Item', 'Count',
                            'Zone Gathers', 'Drop Rate', 'Skill' };

-- The Spoils export covers exactly what Reset Session clears: the tally, and
-- the tools it cost. Tool rows carry no zone, because tool_breaks is keyed by
-- activity alone, and their gil is negative for the same reason the tab draws
-- it in red.
data.EXPORT_SPOILS = T{ 'Character', 'Activity', 'Zone', 'Item', 'Count',
                        'Gil Each', 'Gil Total' };

data.EXPORT_SPOILS_MIN = T{ 'Activity', 'Zone', 'Item', 'Count',
                            'Gil Each', 'Gil Total' };

data.COLOR_SKILLUP  = { 0.40, 0.75, 1.00, 1.00 };

-- The near-cap chip: the zones worth gathering in for skill right now. It is
-- COLOR_SKILLUP because that is what the chip is about -- every skill up rate
-- in the addon is already drawn in it -- and because green on a green plate
-- measured 1.55:1 against the gold state's 3.24:1 and was hard to read. This
-- pairing measures 3.24:1, the same as gold.
--
-- Defined here, below COLOR_SKILLUP, and not beside the other chip colours:
-- table fields resolve in file order, and a forward reference is silently nil.
data.COLOR_CHIP_NEAR     = { 0.11, 0.19, 0.28, 0.90 };
data.COLOR_CHIP_NEAR_INK = data.COLOR_SKILLUP;
data.COLOR_LOCKED   = { 0.45, 0.45, 0.48, 1.00 };

-- Spoils column headings
data.SPOILS_HEADERS = T{ 'ITEM', 'AMOUNT', 'GIL' };

-- Known drops you have not collected
data.TIER_UNSEEN = { rank = 6, name = 'Not seen', color = data.COLOR_LOCKED };
data.TIER_LOCKED = { rank = 7, name = 'Locked',   color = data.COLOR_LOCKED };

-- Fatigue bar
data.COLOR_BAR_BG   = { 0.22, 0.22, 0.26, 0.85 };
data.COLOR_LOW      = { 0.40, 0.75, 1.00, 1.00 };
data.COLOR_MID      = { 1.00, 0.90, 0.20, 1.00 };
data.COLOR_HIGH     = { 0.90, 0.20, 0.20, 1.00 };
data.COLOR_FATIGUED = { 1.00, 0.30, 0.30, 1.00 };
data.COLOR_COST     = data.COLOR_FATIGUED;

-- Dropdown options
local function combo_string(labels)
    local nul = string.char(0);
    local out = '';
    for _, label in ipairs(labels) do
        out = out .. label .. nul;
    end
    return out .. nul;
end

data.UI_SCALES        = T{ 0.75, 1.00, 1.25 };
data.UI_SCALE_DEFAULT = 1.00;
local UI_SCALE_LABELS = T{ '75%', '100%', '125%' };
data.UI_SCALE_COMBO   = combo_string(UI_SCALE_LABELS);

data.ICON_SIZES        = T{ data.ICON_SIZE, data.SPOILS_ICON_SIZE };
data.ICON_SIZE_DEFAULT = data.ICON_SIZE;

data.ITEM_STYLES        = T{ 'Grid', 'List' };
data.ITEM_STYLE_DEFAULT = 'Grid';

data.HOME_MODES        = T{ 'Full', 'Normal', 'Compact' };
data.HOME_MODE_DEFAULT = 'Full';
data.HOME_MODE_COMBO   = combo_string(data.HOME_MODES);

-- Chat forms the resource manager does not index, keyed normalised
data.ITEM_ALIASES = T{
    ['suit of moblin armor'] = 'Moblin Armor',
    ['suit of moblin mail']  = 'Moblin Mail',
};

-- Fonts
data.FONT_DIR = 'C:\\Windows\\Fonts\\';
data.FONTS    = T{
    { name = 'Segoe UI',     file = 'segoeuib.ttf' },
    { name = 'Consolas',     file = 'consolab.ttf' },
    { name = 'Arial',        file = 'arialbd.ttf' },
    { name = 'Tahoma',       file = 'tahomabd.ttf' },
    { name = 'Trebuchet MS', file = 'trebucbd.ttf' },
};
data.FONT_DEFAULT = 'Segoe UI';

local FONT_NAMES = T{};
for _, entry in ipairs(data.FONTS) do table.insert(FONT_NAMES, entry.name); end
data.FONT_NAMES = FONT_NAMES;
data.FONT_COMBO = combo_string(FONT_NAMES);

-- Items each zone is known to drop, and the skill a gated one needs
data.ZONE_ITEMS = T{
    Harvesting = T{
        [51] = T{
            { name = 'Coffee Cherries' },
            { name = 'Eastern Ginger' },
            { name = 'Eggplant' },
            { name = 'Fresh Marjoram' },
            { name = 'Fresh Mugwort', skill = 20 },
            { name = 'Im. Tea Leaves', skill = 10 },
            { name = 'Mohbwa Grass' },
            { name = 'Peph. Hive Chip' },
            { name = 'Red Moko Grass', skill = 10 },
            { name = 'Simsim' },
            { name = 'Wijnruit' },
        },
        [52] = T{
            { name = 'Coffee Cherries' },
            { name = 'Eastern Ginger' },
            { name = 'Eggplant' },
            { name = 'Fresh Marjoram' },
            { name = 'Fresh Mugwort', skill = 20 },
            { name = 'Im. Tea Leaves', skill = 10 },
            { name = 'Mohbwa Grass' },
            { name = 'Peph. Hive Chip' },
            { name = 'Red Moko Grass', skill = 10 },
            { name = 'Simsim' },
            { name = 'Wijnruit' },
        },
        [115] = T{
            { name = 'Beehive Chip' },
            { name = 'Crawler Cocoon' },
            { name = "Dyer's Woad" },
            { name = 'Flax Flower' },
            { name = 'Fresh Mugwort', skill = 10 },
            { name = 'Grain Seeds' },
            { name = 'Herb Seeds' },
            { name = 'Honey' },
            { name = 'Moko Grass' },
            { name = 'Red Moko Grass', skill = 10 },
            { name = 'Saruta Cotton' },
            { name = 'Skull Locust' },
            { name = 'Vegetable Seeds' },
            { name = 'Wild Onion' },
            { name = 'Win. Tea Leaves' },
        },
        [123] = T{
            { name = 'Danceshroom' },
            { name = 'King Truffle', skill = 40 },
            { name = 'Mushrm. Locust' },
            { name = 'Phalaenopsis' },
            { name = 'Puffball', skill = 20 },
            { name = 'Scream Fungus' },
            { name = 'Sleepshroom' },
            { name = 'Toad Oil', skill = 30 },
            { name = 'Woozyshroom' },
        },
        [124] = T{
            { name = 'Cattleya' },
            { name = 'Coral Fungus' },
            { name = 'Danceshroom' },
            { name = 'Malboro Fiber', skill = 40 },
            { name = 'Mistletoe', skill = 30 },
            { name = 'Mushrm. Locust' },
            { name = 'Reishi Mushroom', skill = 20 },
            { name = 'Scream Fungus' },
            { name = 'Sleepshroom' },
            { name = 'Woozyshroom' },
        },
        [145] = T{
            { name = 'Beehive Chip' },
            { name = 'Crawler Cocoon' },
            { name = "Dyer's Woad" },
            { name = 'Flax Flower' },
            { name = 'Fresh Marjoram' },
            { name = 'Fresh Mugwort', skill = 20 },
            { name = 'Grain Seeds' },
            { name = 'Herb Seeds' },
            { name = 'Honey' },
            { name = 'King Locust' },
            { name = 'Moko Grass' },
            { name = 'Phoenix Feather', skill = 30 },
            { name = 'Red Moko Grass', skill = 10 },
            { name = 'Saruta Cotton' },
            { name = 'Spider Web', skill = 30 },
            { name = 'Vegetable Seeds' },
            { name = 'Win. Tea Leaves' },
        },
    },
    Excavation = T{
        [7] = T{
            { name = 'Antlion Jaw', skill = 20 },
            { name = 'Bat Fang' },
            { name = 'Bone Chip' },
            { name = 'Cactus Stems', skill = 20 },
            { name = 'Chicken Bone' },
            { name = 'Emerald', skill = 40 },
            { name = 'Green Rock', skill = 10 },
            { name = 'H.Q. Scp. Shell', skill = 20 },
            { name = 'Scorpion Claw' },
            { name = 'Wyvern Scales', skill = 30 },
        },
        [54] = T{
            { name = 'Aquamarine', skill = 30 },
            { name = 'Black Pearl' },
            { name = 'Bone Chip' },
            { name = 'Chunk of Rock Salt' },
            { name = 'Coral Fragment' },
            { name = 'Crab Shell' },
            { name = 'Gold Ingot', skill = 40 },
            { name = 'High-Quality Crab Shell', skill = 30 },
            { name = 'Lamian Armlet' },
            { name = 'Lapis Lazuli' },
            { name = 'Merrow Scale' },
            { name = 'Oxblood', skill = 30 },
            { name = 'Pearl' },
            { name = 'Pebble' },
            { name = 'Shall Shell' },
            { name = 'Soulflayer Robe', skill = 40 },
            { name = 'Turquoise' },
        },
        [68] = T{
            { name = "Philosopher's Stone", skill = 40 },
        },
        [117] = T{
            { name = 'Bat Fang' },
            { name = 'Bone Chip' },
            { name = 'Chicken Bone' },
            { name = 'Diamond', skill = 40 },
            { name = 'Giant Femur' },
            { name = 'Red Rock', skill = 10 },
            { name = 'Scorpion Claw' },
            { name = 'Scorpion Shell' },
            { name = 'Silica' },
            { name = 'Translucent Rock', skill = 10 },
            { name = 'Turtle Shell' },
        },
        [173] = T{
            { name = 'Antican Pauldron', skill = 20 },
            { name = 'Antican Robe', skill = 20 },
            { name = 'Blue Rock' },
            { name = 'Coral Fragment', skill = 30 },
            { name = 'Crab Shell' },
            { name = 'Fish Scales' },
            { name = 'Helmet Mole', skill = 10 },
            { name = 'Lugworm' },
            { name = 'Pearl', skill = 40 },
            { name = 'Rock Salt' },
            { name = 'Seashell' },
            { name = 'Shall Shell', skill = 10 },
            { name = 'Shell Bug' },
        },
        [198] = T{
            { name = 'Bat Fang' },
            { name = 'Beetle Jaw' },
            { name = 'Beetle Shell' },
            { name = 'Bone Chip' },
            { name = 'Chicken Bone' },
            { name = 'Giant Femur' },
            { name = 'Petrified Log', skill = 20 },
            { name = 'Purple Rock', skill = 10 },
            { name = 'Silica' },
            { name = 'Spinel', skill = 40 },
            { name = 'Topaz', skill = 40 },
            { name = 'Wyvern Scales', skill = 30 },
            { name = 'Yellow Rock', skill = 10 },
        },
    },
    Logging    = T{
        [25] = T{
            { name = 'Ash Log' },
            { name = 'Elm Log' },
            { name = 'Faerie Apple' },
            { name = 'Maple Log' },
            { name = 'Oak Log' },
            { name = 'Tree Cuttings' },
            { name = 'Walnut Log' },
        },
        [79] = T{
            { name = 'Date' },
            { name = 'Dogwood Log' },
            { name = 'Lauan Log' },
            { name = 'Rosewood Log' },
        },
        [101] = T{
            { name = 'Arrowwood Log' },
            { name = 'Ash Log' },
            { name = 'Chestnut' },
            { name = 'Chestnut Log' },
            { name = 'Elm Log', skill = 5 },
            { name = 'Fruit Seeds' },
            { name = 'Maple Log' },
            { name = 'Yew Log' },
        },
        [104] = T{
            { name = 'Acorn' },
            { name = 'Arrowwood Log' },
            { name = 'Ash Log' },
            { name = 'Dryad Root' },
            { name = 'Oak Log' },
            { name = 'Walnut Log' },
            { name = 'Willow Log' },
            { name = 'Yew Log' },
        },
        [118] = T{
            { name = 'Arrowwood Log' },
            { name = 'Buburimu Grape' },
            { name = 'Dryad Root' },
            { name = 'Ebony Log' },
            { name = 'Fruit Seeds' },
            { name = 'Holly Log' },
            { name = 'Lauan Log' },
            { name = 'Rosewood Log' },
            { name = 'Yagudo Cherry' },
        },
        [140] = T{
            { name = 'Arrowwood Log' },
            { name = 'Ash Log' },
            { name = 'Chestnut Log' },
            { name = 'Elm Log' },
            { name = 'Holly Log' },
            { name = 'Maple Log' },
            { name = 'Willow Log' },
        },
    },
    Mining     = T{
        [11] = T{
            { name = 'Copper Ore' },
            { name = 'Darksteel Ore' },
            { name = 'Goblin Die' },
            { name = 'Gold Ore' },
            { name = 'Igneous Rock' },
            { name = 'Iron Ore' },
            { name = 'Moblin Armor' },
            { name = 'Moblin Helm' },
            { name = 'Moblin Mail' },
            { name = 'Mythril Ore' },
            { name = 'Silver Ore' },
            { name = 'Tin Ore' },
            { name = 'Zinc Ore' },
        },
        [142] = T{
            { name = 'Copper Ore' },
            { name = 'Darksteel Ore', skill = 20 },
            { name = 'Flint Stone' },
            { name = 'Gold Ore', skill = 10 },
            { name = 'Iron Ore' },
            { name = 'Pebble' },
            { name = 'Red Rock' },
            { name = 'Silver Ore' },
            { name = 'Tin Ore' },
            { name = 'Zinc Ore' },
        },
        [143] = T{
            { name = 'Black Rock' },
            { name = 'Copper Ore' },
            { name = 'Iron Ore' },
            { name = 'Mythril Ore' },
            { name = 'Painite', skill = 20 },
            { name = 'Pebble' },
            { name = 'Silver Ore' },
            { name = 'Tin Ore' },
            { name = 'Zinc Ore' },
        },
        [172] = T{
            { name = 'Copper Ore' },
            { name = 'Darksteel Ore', skill = 10 },
            { name = 'Iron Ore' },
            { name = 'Pebble' },
            { name = 'Silver Ore' },
            { name = 'Snapping Mole' },
            { name = 'Tin Ore' },
            { name = 'Zinc Ore' },
        },
        [196] = T{
            { name = 'Copper Ore' },
            { name = 'Darksteel Ore' },
            { name = 'Iron Ore' },
            { name = 'Pebble' },
            { name = 'Silver Ore' },
            { name = 'Tin Ore' },
            { name = 'White Rock' },
            { name = 'Zinc Ore' },
        },
    },
};

data.RARITY_TIERS = T{
    { rank = 1, name = 'Common',         min_pct = 20,
      color = { 1.00, 1.00, 1.00, 1.00 } },
    { rank = 2, name = 'Uncommon',       min_pct = 10,
      color = { 0.25, 0.85, 0.35, 1.00 } },
    { rank = 3, name = 'Rare',           min_pct = 5,
      color = { 0.30, 0.60, 1.00, 1.00 } },
    { rank = 4, name = 'Very Rare',      min_pct = 1,
      color = { 0.70, 0.40, 1.00, 1.00 } },
    { rank = 5, name = 'Extremely Rare', min_pct = 0,
      color = { 1.00, 0.55, 0.15, 1.00 } },
};

data.TRACKED_ZONES = T{
    Harvesting = T{
        { id = 115, name = 'West Sarutabaruta',  skill_cap = 10 },
        { id = 145, name = 'Giddeus',            skill_cap = 20 },
        { id = 123, name = 'Yuhtunga Jungle',    skill_cap = 40 },
        { id = 124, name = 'Yhoator Jungle',     skill_cap = 40 },
        { id = 52,  name = 'Bhaflau Thickets',   skill_cap = 60 },
        { id = 51,  name = 'Wajaom Woodlands',   skill_cap = 60 },
    },
    Excavation = T{
        { id = 54,  name = 'Arrapago Reef',      skill_cap = 60 },
        { id = 7,   name = 'Attohwa Chasm',      skill_cap = 40 },
        { id = 68,  name = 'Aydeewa Subterrane', skill_cap = 60 },
        { id = 173, name = 'Korroloka Tunnel',   skill_cap = 20 },
        { id = 198, name = 'Maze of Shakhrami',  skill_cap = 20 },
        { id = 117, name = 'Tahrongi Canyon',    skill_cap = 10 },
    },
    Logging = T{
        { id = 118, name = 'Buburimu Peninsula', skill_cap = 20 },
        { id = 2,   name = "Carpenters' Landing", skill_cap = 10 },
        { id = 101, name = 'East Ronfaure',      skill_cap = 10 },
        { id = 140, name = 'Ghelsba Outpost',    skill_cap = 20 },
        { id = 104, name = 'Jugner Forest' },
        { id = 24,  name = 'Lufaise Meadows',    skill_cap = 40 },
        { id = 25,  name = 'Misareaux Coast',    skill_cap = 40 },
        { id = 124, name = 'Yhoator Jungle',     skill_cap = 40 },
        { id = 123, name = 'Yuhtunga Jungle',    skill_cap = 20 },
        { id = 79,  name = 'Caedarva Mire',      skill_cap = 60 },
        { id = 65,  name = 'Mamook',             skill_cap = 60 },
    },
    Mining = T{
        { id = 196, name = 'Gusgen Mines',       skill_cap = 20 },
        { id = 62,  name = 'Halvung',            skill_cap = 60 },
        { id = 205, name = "Ifrit's Cauldron",   skill_cap = 40 },
        { id = 61,  name = 'Mount Zhayolm',      skill_cap = 60 },
        { id = 12,  name = 'Newton Movalpolos',  skill_cap = 40 },
        { id = 11,  name = 'Oldton Movalpolos',  skill_cap = 40 },
        { id = 143, name = 'Palborough Mines',   skill_cap = 20 },
        { id = 142, name = 'Yughott Grotto',     skill_cap = 10 },
        { id = 172, name = 'Zeruhn Mines',       skill_cap = 10 },
    },
};

data.MESSAGE_PATTERNS = T{
    Harvesting = T{ 'You successfully harvest', 'You harvest' },
    Excavation = T{ 'You successfully dig up', 'You dig up' },
    Logging    = T{ 'You successfully cut off', 'You cut off' },
    Mining     = T{ 'You successfully dig up', 'You dig up' },
};

data.FAILURE_PATTERNS = T{
    Harvesting = T{ 'You are unable to harvest anything', 'Your sickle breaks' },
    Excavation = T{ 'You are unable to mine anything', 'Your pickaxe breaks' },
    Logging    = T{ 'You are unable to log anything', 'You are unable to cut off anything',
                    'Your hatchet breaks' },
    Mining     = T{ 'You are unable to mine anything', 'Your pickaxe breaks' },
};

data.BARREN_PATTERNS = T{
    Harvesting = T{},
    Excavation = T{},
    Logging    = T{ 'Rotting timber splinters' },
    Mining     = T{},
};

-- Special skills, counted when they fire. Logging's are not known yet.
data.PROC_ABILITIES = T{
    Harvesting = T{
        { name = "Gatherer's Discipline", short = 'DISCIPLINE',
          pattern = 'practiced discipline preserves', basis = 'successes' },
    },
    Excavation = T{
        { name = 'Practiced Technique',   short = 'TECHNIQUE',
          pattern = 'practiced technique preserves', basis = 'breaks' },
    },
    Logging    = T{},
    Mining     = T{
        { name = 'Gold Rush',  short = 'GOLD RUSH',
          pattern = 'Gold Rush!', basis = 'successes', repeats = true },
        { name = 'Motherlode', short = 'MOTHERLODE',
          pattern = 'You hit the mother lode', basis = 'successes' },
    },
};

-- Counted alongside whatever else the line is. Matches both shapes: the
-- standalone break and the one folded into a successful gather.
data.BREAK_PATTERNS = T{
    Harvesting = T{ 'sickle breaks' },
    Excavation = T{ 'pickaxe breaks' },
    Logging    = T{ 'hatchet breaks' },
    Mining     = T{ 'pickaxe breaks' },
};

data.FATIGUE_PATTERN = 'You sense there is little more to be gained from this area.';

local SKILL_NAMES = T{
    Harvesting = 'harvesting',
    Excavation = 'excavating',
    Logging    = 'logging',
    Mining     = 'mining',
};

data.SKILL_MARKER        = 'skill has increased';
data.SKILL_VALUE_DECIMAL = 'raising it to (%d+%.%d+)';
data.SKILL_VALUE_INTEGER = 'raising it to (%d+)';

data.CHARACTER_KEYS = T{ 'fatigue', 'fatigued', 'item_log', 'skill',
                         'skillups', 'attempts', 'successes', 'spoils',
                         'since_skillup', 'procs', 'breaks', 'goldrush',
                         'tool_breaks', 'lifetime', 'session_log' };
data.SESSION_KEYS   = T{ 'skillups', 'attempts', 'successes', 'spoils',
                         'since_skillup', 'tool_breaks', 'session_log' };
data.SPOILS_KEYS    = T{ 'spoils', 'tool_breaks', 'session_log' };
data.SESSION_CLOCK  = T{ 'session_start', 'session_last', 'session_active' };

data.SECONDS_PER_HOUR = 3600;

-- Longer than this between two gathers and the gap is not counted as time
-- spent gathering. Fifteen minutes: hunting for a node can genuinely take
-- twenty, so a shorter cutoff throws away real gathering time, and a longer one
-- starts counting being away from the keyboard.
data.SESSION_IDLE_CUTOFF = 900;

data.PROC_GAP        = 18.0;
-- Within this many skill of a zone's cap and the chip goes green.
data.CAP_NEAR        = 20;

data.CHIP_PAD        = 6.0;
data.CHIP_INSET      = 2.0;
data.STAT_GAP        = 20.0;

-- Nav row furniture, in place of the title bar
data.NAV_EDGE_PAD     = 7.0;
data.NAV_TRACK_PAD    = 3.0;
data.NAV_BTN_PAD_X    = 8.0;
data.NAV_BTN_PAD_Y    = 3.0;
data.NAV_BTN_ROUNDING = 5.0;
data.NAV_DOT          = 2.0;
data.NAV_DOT_GAP      = 2.0;
data.NAV_CLOSE_SIZE   = 7.0;
data.NAV_CLOSE_WEIGHT = 1.5;

-- HELM interaction, and the render bit that clears when an entity despawns
data.HELM_PACKET    = 0x36;
data.RENDER_VISIBLE = 0x200;
-- A node id describes the swing that just happened, never the next one
data.NODE_WINDOW_SECONDS = 3.0;
data.REPEAT_WINDOW_SECONDS = 30.0;

data.CONFIRM_LABEL   = 'Confirm?';
data.CONFIRM_SECONDS = 3.0;
data.BUTTON_PAD      = 10.0;

data.TRACKED_ZONE_SET = T{};
data.ZONE_ACTIVITIES  = T{};
data.SKILL_PATTERNS   = T{};
data.ZONE_LABELS      = T{};

-- Legacy: listed as HELM drops on the HorizonXI wiki but never seen by this
-- addon, and not in the spreadsheet. They exist here only so a price can be set
-- for them. Delete a name once the game confirms it is not a real item; the
-- price editor draws (?) beside anything the resource manager cannot resolve,
-- which is how that gets confirmed. Harvesting is deliberately absent.
data.LEGACY_ITEMS = T{
    Harvesting = T{},
    Excavation = T{
        'Grain Seeds',
        'Little Worm',
        'Vegetable Seeds',
        'Wyvern Egg',
    },
    Logging    = T{
        'Beehive Chip',
        'Dragon Fruit',
        'Kitron',
        'Lqr. Tree Sap',
        'Mahogany Log',
        'Persikos',
        'Petrified Log',
        'Rattan Lumber',
        'Revival Tree Root',
    },
    Mining     = T{
        'Adaman Ore',
        'Aht Urhgan Brass',
        'Aluminum Ore',
        'Bomb Arm',
        'Bomb Ash',
        'Demon Horn',
        'Green Rock',
        'Iron Sand',
        'Khroma Ore',
        'Luminium Ore',
        'Mine Gravel',
        'Moblin Mask',
        'Orichalcum Ore',
        'Orpiment',
        'Platinum Ore',
        'Plumbago',
        'Sulfur',
        'Troll Pauldron',
        'Troll Vambrace',
        'Yellow Rock',
    },
};

data.LEGACY_SET    = T{};
data.PRICE_ITEMS   = T{};
data.SKILL_CAPS    = T{};
data.PROC_PATTERNS = T{};
data.PROC_NAMES    = T{};
data.PROC_REPEATS  = T{};

for _, activity in ipairs(data.ACTIVITIES) do
    local procs = T{};
    for _, ability in ipairs(data.PROC_ABILITIES[activity]) do
        table.insert(procs, ability.pattern);
        data.PROC_NAMES[ability.pattern] = ability.name;
        if (ability.repeats) then data.PROC_REPEATS[ability.name] = true; end
    end
    data.PROC_PATTERNS[activity] = procs;

    -- Display order: the zone whose cap you will reach first, first. Ties go
    -- alphabetical, and a zone whose cap is not yet known sorts to the bottom
    -- rather than to the top, where an absent cap would read as zero. Sorted
    -- once here rather than in the render path, which walks this list every
    -- frame and must not sort it.
    table.sort(data.TRACKED_ZONES[activity], function(a, b)
        local ca, cb = a.skill_cap, b.skill_cap;
        if (ca ~= cb) then
            if (ca == nil) then return false; end
            if (cb == nil) then return true; end
            return ca < cb;
        end
        return a.name < b.name;
    end);

    local set  = T{};
    local caps = T{};
    for _, zone in ipairs(data.TRACKED_ZONES[activity]) do
        set[zone.id]             = true;
        data.ZONE_LABELS[zone.id] = zone.name;

        if (zone.skill_cap ~= nil) then
            caps[zone.id] = zone.skill_cap;
        end

        data.ZONE_ACTIVITIES[zone.id] = data.ZONE_ACTIVITIES[zone.id] or T{};
        table.insert(data.ZONE_ACTIVITIES[zone.id], activity);
    end
    data.TRACKED_ZONE_SET[activity] = set;
    data.SKILL_CAPS[activity]       = caps;
    local named, names = T{}, T{};
    for _, entries in pairs(data.ZONE_ITEMS[activity] or T{}) do
        for _, entry in ipairs(entries) do
            if (not named[entry.name]) then
                named[entry.name] = true;
                table.insert(names, entry.name);
            end
        end
    end

    local legacy = T{};
    for _, name in ipairs(data.LEGACY_ITEMS[activity]) do
        if (not named[name]) then
            named[name]  = true;
            legacy[name] = true;
            table.insert(names, name);
        end
    end

    table.sort(names);
    data.PRICE_ITEMS[activity] = names;
    data.LEGACY_SET[activity]  = legacy;

    data.SKILL_PATTERNS[activity]   =
        ('Your %s skill has increased'):fmt(SKILL_NAMES[activity]);
end

-- Tools
data.TOOL_KEY       = 'Tools';
data.ACTIVITY_TOOLS = T{
    Harvesting = 'Sickle',
    Excavation = 'Pickaxe',
    Logging    = 'Hatchet',
    Mining     = 'Pickaxe',
};

local TOOL_NAMES, tooled = T{}, T{};
for _, activity in ipairs(data.ACTIVITIES) do
    local tool = data.ACTIVITY_TOOLS[activity];
    if (not tooled[tool]) then
        tooled[tool] = true;
        table.insert(TOOL_NAMES, tool);
    end
end
table.sort(TOOL_NAMES);
data.PRICE_ITEMS[data.TOOL_KEY] = TOOL_NAMES;
data.LEGACY_SET[data.TOOL_KEY]  = T{};

data.PRICE_BLOCKS = T{};
for _, activity in ipairs(data.ACTIVITIES) do
    table.insert(data.PRICE_BLOCKS, activity);
end
table.insert(data.PRICE_BLOCKS, data.TOOL_KEY);

return data;

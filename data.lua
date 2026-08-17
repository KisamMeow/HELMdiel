require('common');

local data = T{};

-- The mechanic
data.FATIGUE_CAP          = 200;
data.FATIGUE_WARN         = 150;
data.DEDUP_WINDOW_SECONDS = 1.0;
data.DEDUP_QUIET_SECONDS  = 0.10;

data.ACTIVITIES = T{ 'Harvesting', 'Excavation', 'Logging', 'Mining' };

-- Chat modes a player can type on. Anything arriving on one of these is
-- somebody talking, never the game reporting a gather.
data.CHAT_MODE_MASK = 256;

data.PLAYER_CHAT_MODES = T{
    -- Outgoing 1-6, incoming 9-14, the same channels eight apart. 7 and 8 are
    -- unobserved and blocked with them: the whole low block is social chat and
    -- every system message seen sits at 121 or above.
    [1]   = true,   -- say, outgoing
    [2]   = true,   -- shout, outgoing
    [3]   = true,   -- yell, outgoing
    [4]   = true,   -- tell, outgoing
    [5]   = true,   -- party, outgoing
    [6]   = true,   -- linkshell, outgoing
    [7]   = true,
    [8]   = true,
    [9]   = true,   -- say
    [10]  = true,   -- shout
    [11]  = true,   -- yell
    [12]  = true,   -- tell
    [13]  = true,   -- party
    [14]  = true,   -- linkshell

    [157] = true,   -- the echo of a command you typed
    [212] = true,   -- unity
    [213] = true,   -- linkshell 2, outgoing
    [214] = true,   -- linkshell 2
    [220] = true,   -- assist, ja
    [222] = true,   -- assist, en
};

-- Nav order
data.NAV_LEADING  = T{ 'Home' };
data.NAV_TRAILING = T{ 'Spoils', 'Settings' };

-- Pixel sizes
data.SKILL_INPUT_WIDTH  = 70;
data.FATIGUE_BAR_HEIGHT = 14.0;
data.ICON_SIZE         = 32;
data.SPOILS_ICON_SIZE  = 16;
data.ITEMS_PER_ROW     = 3;
data.CELL_PADDING      = 4.0;
data.CELL_BORDER       = 2.0;
data.CELL_GUTTER       = 14;
data.NAV_GAP           = 6.0;
data.FRAME_ROUNDING    = 5.0;
data.WINDOW_ROUNDING   = 6.0;
data.TITLE_ALIGN       = { 0.5, 0.5 };

data.FONT_PATH = 'C:\\Windows\\Fonts\\segoeuib.ttf';
data.FONT_SIZE = 18.0;

data.SMALL_ICON_FONT_DROP = 2.0;
data.ITEM_LINE_GAP        = 1.0;

data.WINDOW_OPACITY = 0.75;
data.OPACITY_MIN    = 0.10;
data.OPACITY_MAX    = 1.00;

-- Gold accent and resize grip
data.COLOR_GOLD        = { 1.00, 0.84, 0.20, 1.00 };
data.COLOR_GRIP        = { 1.00, 0.84, 0.20, 0.85 };
data.COLOR_GRIP_HOVER  = { 1.00, 0.90, 0.45, 1.00 };
data.COLOR_GRIP_ACTIVE = { 1.00, 1.00, 0.75, 1.00 };

-- Chrome
data.COLOR_BUTTON        = { 0.14, 0.14, 0.15, 0.90 };
data.COLOR_BUTTON_HOVER  = { 0.26, 0.26, 0.28, 0.95 };
data.COLOR_BUTTON_ACTIVE = { 0.33, 0.33, 0.35, 1.00 };
data.COLOR_NAV_SELECTED  = { 0.40, 0.40, 0.43, 1.00 };
data.COLOR_HEADER        = { 0.19, 0.19, 0.20, 0.65 };
data.COLOR_HEADER_HOVER  = { 0.28, 0.28, 0.30, 0.85 };
data.COLOR_HEADER_ACTIVE = { 0.34, 0.34, 0.36, 0.95 };

-- Destructive buttons
data.COLOR_DANGER        = { 0.45, 0.16, 0.16, 0.90 };
data.COLOR_DANGER_HOVER  = { 0.60, 0.20, 0.20, 0.95 };
data.COLOR_DANGER_ACTIVE = { 0.72, 0.24, 0.24, 1.00 };

-- Export button
data.COLOR_SUCCESS        = { 0.16, 0.42, 0.20, 0.90 };
data.COLOR_SUCCESS_HOVER  = { 0.22, 0.56, 0.26, 0.95 };
data.COLOR_SUCCESS_ACTIVE = { 0.28, 0.68, 0.32, 1.00 };

-- CSV export columns
data.EXPORT_HEADER = T{ 'Character', 'Activity', 'Zone', 'Item', 'Count',
                        'Zone Gathers', 'Drop Rate', 'Fatigue', 'Attempts',
                        'Successes', 'Skill Ups', 'Skill' };

data.EXPORT_HEADER_MIN = T{ 'Activity', 'Zone', 'Item', 'Count',
                            'Zone Gathers', 'Drop Rate', 'Skill' };

data.COLOR_SKILLUP  = { 0.40, 0.75, 1.00, 1.00 };

-- Fatigue bar
data.COLOR_BAR_BG   = { 0.16, 0.16, 0.18, 0.85 };
data.COLOR_LOW      = { 0.40, 0.75, 1.00, 1.00 };
data.COLOR_MID      = { 1.00, 0.90, 0.20, 1.00 };
data.COLOR_HIGH     = { 0.90, 0.20, 0.20, 1.00 };
data.COLOR_FATIGUED = { 1.00, 0.30, 0.30, 1.00 };

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
local ICON_SIZE_LABELS = T{ 'Large', 'Small' };
data.ICON_SIZE_COMBO   = combo_string(ICON_SIZE_LABELS);

data.ITEM_STYLES        = T{ 'Grid', 'List' };
data.ITEM_STYLE_DEFAULT = 'Grid';
data.ITEM_STYLE_COMBO   = combo_string(data.ITEM_STYLES);

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
        { id = 115, name = 'West Sarutabaruta', skill_cap = 10 },
        { id = 145, name = 'Giddeus',           skill_cap = 20 },
        { id = 123, name = 'Yuhtunga Jungle',   skill_cap = 40 },
        { id = 124, name = 'Yhoator Jungle',    skill_cap = 40 },
        { id = 52,  name = 'Bhaflau Thickets' },
        { id = 51,  name = 'Wajaom Woodlands' },
    },
    Excavation = T{
        { id = 7,   name = 'Attohwa Chasm' },
        { id = 173, name = 'Korroloka Tunnel',  skill_cap = 20 },
        { id = 198, name = 'Maze of Shakhrami', skill_cap = 20 },
        { id = 117, name = 'Tahrongi Canyon',   skill_cap = 10 },
    },
    Logging = T{
        { id = 118, name = 'Buburimu Peninsula' },
        { id = 2,   name = "Carpenters' Landing" },
        { id = 101, name = 'East Ronfaure' },
        { id = 140, name = 'Ghelsba Outpost' },
        { id = 104, name = 'Jugner Forest' },
        { id = 24,  name = 'Lufaise Meadows' },
        { id = 25,  name = 'Misareaux Coast' },
        { id = 124, name = 'Yhoator Jungle' },
        { id = 123, name = 'Yuhtunga Jungle' },
        { id = 79,  name = 'Caedarva Mire' },
        { id = 65,  name = 'Mamook' },
    },
    Mining = T{
        { id = 196, name = 'Gusgen Mines' },
        { id = 205, name = "Ifrit's Cauldron" },
        { id = 12,  name = 'Newton Movalpolos' },
        { id = 11,  name = 'Oldton Movalpolos' },
        { id = 143, name = 'Palborough Mines' },
        { id = 142, name = 'Yughott Grotto' },
        { id = 172, name = 'Zeruhn Mines' },
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
        { name = "Gatherer's Discipline", pattern = 'practiced discipline preserves',
          basis = 'successes' },
    },
    Excavation = T{
        { name = 'Practiced Technique',   pattern = 'practiced technique preserves',
          basis = 'breaks' },

    },
    Logging    = T{},
    Mining     = T{
        { name = 'Gold Rush',  pattern = 'Gold Rush!',
          basis = 'successes' },
        { name = 'Motherlode', pattern = 'You hit the mother lode',
          basis = 'successes' },
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
                         'since_skillup', 'procs', 'breaks' };
data.SESSION_KEYS   = T{ 'skillups', 'attempts', 'successes', 'spoils',
                         'since_skillup' };

data.TRACKED_ZONE_SET = T{};
data.ZONE_ACTIVITIES  = T{};
data.SKILL_PATTERNS   = T{};
data.ZONE_LABELS      = T{};

data.SKILL_CAPS    = T{};
data.PROC_PATTERNS = T{};
data.PROC_NAMES    = T{};

for _, activity in ipairs(data.ACTIVITIES) do
    local procs = T{};
    for _, ability in ipairs(data.PROC_ABILITIES[activity]) do
        table.insert(procs, ability.pattern);
        data.PROC_NAMES[ability.pattern] = ability.name;
    end
    data.PROC_PATTERNS[activity] = procs;

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
    data.SKILL_PATTERNS[activity]   =
        ('Your %s skill has increased'):fmt(SKILL_NAMES[activity]);
end

return data;

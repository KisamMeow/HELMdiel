require('common');

local data = T{};

data.FATIGUE_CAP          = 200;
data.FATIGUE_WARN         = 150;
data.DEDUP_WINDOW_SECONDS = 3.5;
data.SKILL_INPUT_WIDTH    = 70;

data.ACTIVITIES = T{ 'Harvesting', 'Excavation', 'Logging', 'Mining' };

data.COLOR_LOW      = { 0.40, 0.75, 1.00, 1.00 };
data.COLOR_MID      = { 1.00, 0.90, 0.20, 1.00 };
data.COLOR_HIGH     = { 0.90, 0.20, 0.20, 1.00 };
data.COLOR_FATIGUED = { 1.00, 0.30, 0.30, 1.00 };

data.RARITY_TIERS = T{
    { rank = 1, name = 'Common',         min_pct = 20 },
    { rank = 2, name = 'Uncommon',       min_pct = 10 },
    { rank = 3, name = 'Rare',           min_pct = 5  },
    { rank = 4, name = 'Very Rare',      min_pct = 1  },
    { rank = 5, name = 'Extremely Rare', min_pct = 0  },
};

data.TRACKED_ZONES = T{
    Harvesting = T{
        { id = 115, name = 'West Sarutabaruta', skill_cap = 10 },
        { id = 145, name = 'Giddeus',           skill_cap = 20 },
        { id = 123, name = 'Yuhtunga Jungle',   skill_cap = 30 },
        { id = 124, name = 'Yhoator Jungle',    skill_cap = 30 },
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
                         'skillups', 'attempts', 'successes' };
data.SESSION_KEYS   = T{ 'skillups', 'attempts', 'successes' };

data.TRACKED_ZONE_SET = T{};
data.ZONE_ACTIVITIES  = T{};
data.SKILL_PATTERNS   = T{};
data.ZONE_LABELS      = T{};

for _, activity in ipairs(data.ACTIVITIES) do
    local set = T{};
    for _, zone in ipairs(data.TRACKED_ZONES[activity]) do
        set[zone.id]             = true;
        data.ZONE_LABELS[zone.id] = zone.name;

        data.ZONE_ACTIVITIES[zone.id] = data.ZONE_ACTIVITIES[zone.id] or T{};
        table.insert(data.ZONE_ACTIVITIES[zone.id], activity);
    end
    data.TRACKED_ZONE_SET[activity] = set;
    data.SKILL_PATTERNS[activity]   =
        ('Your %s skill has increased'):fmt(SKILL_NAMES[activity]);
end

return data;

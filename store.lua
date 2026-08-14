require('common');

local settings = require('settings');
local data     = require('data');

local store = T{};

local default_settings = T{
    characters = T{},
    window     = T{
        auto_popup   = true,
        home_minimum = false,
    },
    activities = T{
        Harvesting = true,
        Excavation = true,
        Logging    = true,
        Mining     = true,
    },
};

local helm_settings = settings.load(default_settings);
helm_settings.activities = helm_settings.activities or T{};
helm_settings.window     = helm_settings.window or T{};

settings.register('settings', 'settings_update', function(s)
    if (s ~= nil) then
        helm_settings = s;
    end
    settings.save();
end);

local EMPTY_LOG = T{};
local ZONE_KEYS = T{};

local function zone_key(zoneId)
    local key = ZONE_KEYS[zoneId];
    if (key == nil) then
        key = tostring(zoneId);
        ZONE_KEYS[zoneId] = key;
    end
    return key;
end

function store.save()
    settings.save();
end

function store.player()
    local party = AshitaCore:GetMemoryManager():GetParty();
    if (party == nil) then return 'unknown', 0; end

    local name = party:GetMemberName(0);
    if (name == nil or name == '') then name = 'unknown'; end

    return name, (party:GetMemberZone(0) or 0);
end

function store.char_name()
    local name = store.player();
    return name;
end

function store.zone_id()
    local _, zoneId = store.player();
    return zoneId;
end

----------------------------------------
-- Preferences
----------------------------------------

function store.activity_enabled(activity)
    local value = helm_settings.activities[activity];
    if (value == nil) then return true; end
    return value;
end

function store.toggle_activity(activity)
    helm_settings.activities[activity] = not store.activity_enabled(activity);
    settings.save();
end

function store.auto_popup()
    return helm_settings.window.auto_popup == true;
end

function store.toggle_auto_popup()
    helm_settings.window.auto_popup = not store.auto_popup();
    settings.save();
end

function store.home_minimum()
    return helm_settings.window.home_minimum == true;
end

function store.toggle_home_minimum()
    helm_settings.window.home_minimum = not store.home_minimum();
    settings.save();
end

----------------------------------------
-- Character records
----------------------------------------

local function ensure_char(charname)
    local char = helm_settings.characters[charname] or T{};
    helm_settings.characters[charname] = char;

    for _, key in ipairs(data.CHARACTER_KEYS) do
        char[key] = char[key] or T{};
    end
    return char;
end

local function ensure_zone(charname, field, activity, zoneId, empty)
    local group = ensure_char(charname)[field];
    group[activity] = group[activity] or T{};

    if (zoneId == nil) then return group[activity]; end

    local key = zone_key(zoneId);
    if (empty ~= nil) then
        group[activity][key] = group[activity][key] or empty();
    end
    return group[activity], key;
end

local function read_zone(charname, field, activity, zoneId, missing)
    local char = helm_settings.characters[charname];
    if (char == nil or char[field] == nil or char[field][activity] == nil) then
        return missing;
    end
    return char[field][activity][zone_key(zoneId)] or missing;
end

local function bump(field, activity, zoneId)
    local group, key = ensure_zone(store.char_name(), field, activity, zoneId);
    group[key] = (group[key] or 0) + 1;
end

function store.get_fatigue(charname, activity, zoneId)
    return read_zone(charname, 'fatigue', activity, zoneId, 0);
end

function store.get_attempts(charname, activity, zoneId)
    return read_zone(charname, 'attempts', activity, zoneId, 0);
end

function store.get_successes(charname, activity, zoneId)
    return read_zone(charname, 'successes', activity, zoneId, 0);
end

function store.get_skillups(charname, activity, zoneId)
    return read_zone(charname, 'skillups', activity, zoneId, 0);
end

function store.get_item_log(charname, activity, zoneId)
    return read_zone(charname, 'item_log', activity, zoneId, EMPTY_LOG);
end

function store.is_fatigued(charname, activity, zoneId)
    return read_zone(charname, 'fatigued', activity, zoneId, false) == true;
end

function store.get_skill(charname, activity)
    local char = helm_settings.characters[charname];
    if (char == nil or char.skill == nil) then return nil; end
    return char.skill[activity];
end

function store.set_skill(charname, activity, value)
    ensure_char(charname).skill[activity] = value;
end

function store.set_fatigue(charname, activity, zoneId, value)
    local group, key = ensure_zone(charname, 'fatigue', activity, zoneId);
    group[key] = math.max(0, math.min(data.FATIGUE_CAP, value));

    if (group[key] < data.FATIGUE_CAP) then
        local flags, flagKey = ensure_zone(charname, 'fatigued', activity, zoneId);
        flags[flagKey] = nil;
    end
end

----------------------------------------
-- Recording events
----------------------------------------

function store.register_gather(activity, zoneId)
    local charname     = store.char_name();
    local fatigue, key = ensure_zone(charname, 'fatigue', activity, zoneId);
    local flags        = ensure_zone(charname, 'fatigued', activity, zoneId);

    fatigue[key] = math.min(data.FATIGUE_CAP, (fatigue[key] or 0) + 1);
    flags[key]   = nil;

    for zid, value in pairs(fatigue) do
        if (zid ~= key) then
            fatigue[zid] = math.max(0, value - 1);
            if (fatigue[zid] < data.FATIGUE_CAP) then
                flags[zid] = nil;
            end
        end
    end
end

function store.register_fatigue_cap(activity, zoneId)
    local charname     = store.char_name();
    local fatigue, key = ensure_zone(charname, 'fatigue', activity, zoneId);
    local flags        = ensure_zone(charname, 'fatigued', activity, zoneId);

    fatigue[key] = data.FATIGUE_CAP;

    for zid in pairs(fatigue) do
        if (zid ~= key) then fatigue[zid] = 0; end
    end
    for zid in pairs(flags) do
        flags[zid] = nil;
    end

    flags[key] = true;
end

function store.register_item_gather(activity, zoneId, itemName)
    if (itemName == nil) then return; end
    local group, key = ensure_zone(store.char_name(), 'item_log', activity, zoneId, T);
    group[key][itemName] = (group[key][itemName] or 0) + 1;
end

function store.register_skill(activity, value)
    store.set_skill(store.char_name(), activity, value);
end

function store.register_attempt(activity, zoneId) bump('attempts',  activity, zoneId); end
function store.register_success(activity, zoneId) bump('successes', activity, zoneId); end
function store.register_skillup(activity, zoneId) bump('skillups',  activity, zoneId); end

----------------------------------------
-- Resets
----------------------------------------

function store.reset_session()
    local char = ensure_char(store.char_name());
    for _, key in ipairs(data.SESSION_KEYS) do
        char[key] = T{};
    end
    settings.save();
end

function store.reset_all()
    local charname = store.char_name();
    helm_settings.characters[charname] = nil;
    ensure_char(charname);
    settings.save();
end

function store.reset_activity(charname, activity)
    ensure_char(charname).fatigue[activity] = T{};
    settings.save();
end

return store;

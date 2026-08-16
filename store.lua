require('common');

local settings = require('settings');
local data     = require('data');

local store = T{};

local default_settings = T{
    characters = T{},
    window     = T{
        auto_popup   = true,
        home_minimum = false,
        item_icons   = true,
        auto_resize  = true,
        opacity      = data.WINDOW_OPACITY,
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

function store.config_path()
    return ('%s/config/addons/%s/'):fmt(AshitaCore:GetInstallPath(), addon.name);
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

function store.item_icons()
    return helm_settings.window.item_icons ~= false;
end

function store.toggle_item_icons()
    helm_settings.window.item_icons = not store.item_icons();
    settings.save();
end

function store.auto_resize()
    return helm_settings.window.auto_resize ~= false;
end

function store.toggle_auto_resize()
    helm_settings.window.auto_resize = not store.auto_resize();
    settings.save();
end

function store.export_minimal()
    return helm_settings.window.export_minimal == true;
end

function store.toggle_export_minimal()
    helm_settings.window.export_minimal = not store.export_minimal();
    settings.save();
end

local function choice(key, options, fallback)
    local value = helm_settings.window[key];
    for _, option in ipairs(options) do
        if (value == option) then return value; end
    end
    return fallback;
end

local function choice_index(key, options, fallback)
    local current = choice(key, options, fallback);
    for index, option in ipairs(options) do
        if (option == current) then return index; end
    end
    return 1;
end

local function set_choice(key, options, index)
    local value = options[index];
    if (value == nil) then return; end
    helm_settings.window[key] = value;
    settings.save();
end

function store.ui_scale()
    return choice('ui_scale', data.UI_SCALES, data.UI_SCALE_DEFAULT);
end

function store.ui_scale_index()
    return choice_index('ui_scale', data.UI_SCALES, data.UI_SCALE_DEFAULT);
end

function store.set_ui_scale_index(index)
    set_choice('ui_scale', data.UI_SCALES, index);
end

function store.icon_size()
    return choice('icon_size', data.ICON_SIZES, data.ICON_SIZE_DEFAULT);
end

function store.icon_size_index()
    return choice_index('icon_size', data.ICON_SIZES, data.ICON_SIZE_DEFAULT);
end

function store.set_icon_size_index(index)
    set_choice('icon_size', data.ICON_SIZES, index);
end

function store.item_style()
    return choice('item_style', data.ITEM_STYLES, data.ITEM_STYLE_DEFAULT);
end

function store.item_style_index()
    return choice_index('item_style', data.ITEM_STYLES, data.ITEM_STYLE_DEFAULT);
end

function store.set_item_style_index(index)
    set_choice('item_style', data.ITEM_STYLES, index);
end

local function clamp_opacity(value)
    return math.min(data.OPACITY_MAX, math.max(data.OPACITY_MIN, value));
end

function store.window_opacity()
    local value = helm_settings.window.opacity;
    if (type(value) ~= 'number') then return data.WINDOW_OPACITY; end
    return clamp_opacity(value);
end

function store.set_window_opacity(value)
    if (type(value) ~= 'number') then return; end
    helm_settings.window.opacity = clamp_opacity(value);
    settings.save();
end

----------------------------------------
-- Character records
----------------------------------------

local function ensure_char(charname)
    local char = helm_settings.characters[charname] or T{};
    helm_settings.characters[charname] = char;

    for _, key in ipairs(data.CHARACTER_KEYS) do
        if (type(char[key]) ~= 'table') then char[key] = T{}; end
    end
    return char;
end

local function ensure_zone(charname, field, activity, zoneId, empty)
    local char  = ensure_char(charname);
    local group = char[field];
    if (type(group[activity]) ~= 'table') then group[activity] = T{}; end

    if (zoneId == nil) then return group[activity], nil, char; end

    local key = zone_key(zoneId);
    if (empty ~= nil) then
        group[activity][key] = group[activity][key] or empty();
    end
    return group[activity], key, char;
end

local function read_zone(charname, field, activity, zoneId, missing)
    local char = helm_settings.characters[charname];
    if (char == nil or char[field] == nil
        or type(char[field][activity]) ~= 'table') then
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

function store.get_since_skillup(charname, activity)
    local char = helm_settings.characters[charname];
    if (char == nil or char.since_skillup == nil) then return 0; end
    return char.since_skillup[activity] or 0;
end

function store.get_breaks(charname, activity, zoneId)
    return read_zone(charname, 'breaks', activity, zoneId, 0);
end

function store.get_proc(charname, name, zoneId)
    return read_zone(charname, 'procs', name, zoneId, 0);
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

function store.get_spoils(charname)
    local char = helm_settings.characters[charname];
    if (char == nil or char.spoils == nil) then return EMPTY_LOG; end
    return char.spoils;
end

function store.register_item_gather(activity, zoneId, itemName)
    if (itemName == nil) then return; end

    local group, key, char = ensure_zone(store.char_name(), 'item_log',
                                         activity, zoneId, T);
    group[key][itemName]  = (group[key][itemName] or 0) + 1;
    char.spoils[itemName] = (char.spoils[itemName] or 0) + 1;
end

function store.register_skill(activity, value)
    store.set_skill(store.char_name(), activity, value);
end

function store.register_attempt(activity, zoneId) bump('attempts',  activity, zoneId); end
function store.register_success(activity, zoneId) bump('successes', activity, zoneId); end
function store.register_skillup(activity, zoneId) bump('skillups',  activity, zoneId); end

function store.bump_since_skillup(activity)
    local char = ensure_char(store.char_name());
    char.since_skillup[activity] = (char.since_skillup[activity] or 0) + 1;
end

function store.register_break(activity, zoneId) bump('breaks', activity, zoneId); end
function store.register_proc(name, zoneId)      bump('procs',  name,     zoneId); end

function store.reset_since_skillup(activity)
    ensure_char(store.char_name()).since_skillup[activity] = 0;
end

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

function store.reset_spoils()
    ensure_char(store.char_name()).spoils = T{};
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

addon.name    = 'HHelmet';
addon.author  = 'Masuru';
addon.version = '0.6.1';
addon.desc    = 'Tracks HELM (Harvesting/Excavation/Logging/Mining) regional gathering fatigue on HorizonXI.';
addon.link    = 'https://github.com/KisamMeow/HHelmet';

require('common');
local settings = require('settings');
local imgui    = require('imgui');
local chat     = require('chat');

----------------------------------------
-- Constants
----------------------------------------

local FATIGUE_CAP          = 200;
local FATIGUE_WARN         = 150;
local DEDUP_WINDOW_SECONDS = 3.5;
local SKILL_INPUT_WIDTH    = 70;

local ACTIVITIES = T{ 'Harvesting', 'Excavation', 'Logging', 'Mining' };

local COLOR_LOW       = { 0.40, 0.75, 1.00, 1.00 };
local COLOR_MID       = { 1.00, 0.90, 0.20, 1.00 };
local COLOR_HIGH      = { 0.90, 0.20, 0.20, 1.00 };
local COLOR_FATIGUED  = { 1.00, 0.30, 0.30, 1.00 };

local RARITY_TIERS = T{
    { rank = 1, name = 'Common',         min_pct = 20 },
    { rank = 2, name = 'Uncommon',       min_pct = 10 },
    { rank = 3, name = 'Rare',           min_pct = 5  },
    { rank = 4, name = 'Very Rare',      min_pct = 1  },
    { rank = 5, name = 'Extremely Rare', min_pct = 0  },
};

local TRACKED_ZONES = T{
    Harvesting = T{
        { id = 115, name = 'West Sarutabaruta', skill_min = 0,  skill_max = 10 },
        { id = 145, name = 'Giddeus',           skill_min = 0,  skill_max = 20 },
        { id = 123, name = 'Yuhtunga Jungle',   skill_min = 10, skill_max = 30 },
        { id = 124, name = 'Yhoator Jungle',    skill_min = 20, skill_max = 40 },
        { id = 52,  name = 'Bhaflau Thickets' },
        { id = 51,  name = 'Wajaom Woodlands' },
    },
    Excavation = T{
        { id = 7,   name = 'Attohwa Chasm' },
        { id = 173, name = 'Korroloka Tunnel' },
        { id = 198, name = 'Maze of Shakhrami' },
        { id = 117, name = 'Tahrongi Canyon' },
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

local MESSAGE_PATTERNS = T{
    Harvesting = T{ 'You successfully harvest', 'You harvest' },
    Excavation = T{ 'You successfully dig up', 'You dig up' },
    Logging    = T{ 'You successfully cut off', 'You cut off' },
    Mining     = T{ 'You successfully dig up', 'You dig up' },
};

local FAILURE_PATTERNS = T{
    Harvesting = T{ 'You are unable to harvest anything' },
    Excavation = T{ 'You are unable to mine anything' },
    Logging    = T{ 'You are unable to log anything', 'You are unable to cut off anything' },
    Mining     = T{ 'You are unable to mine anything' },
};

local FATIGUE_PATTERN = 'You sense there is little more to be gained from this area.';

local SKILL_NAMES = T{
    Harvesting = 'harvesting',
    Excavation = 'excavating',
    Logging    = 'logging',
    Mining     = 'mining',
};

local SKILL_MARKER        = 'skill has increased';
local SKILL_VALUE_DECIMAL = 'raising it to (%d+%.%d+)';
local SKILL_VALUE_INTEGER = 'raising it to (%d+)';

local TRACKED_ZONE_SET  = T{};
local ZONE_NAMES        = T{};
local ZONE_ACTIVITIES   = T{};
local SKILL_PATTERNS    = T{};

for _, activity in ipairs(ACTIVITIES) do
    local set = T{};
    for _, zone in ipairs(TRACKED_ZONES[activity]) do
        set[zone.id]        = true;
        ZONE_NAMES[zone.id] = zone.name;

        ZONE_ACTIVITIES[zone.id] = ZONE_ACTIVITIES[zone.id] or T{};
        table.insert(ZONE_ACTIVITIES[zone.id], activity);
    end
    TRACKED_ZONE_SET[activity] = set;
    SKILL_PATTERNS[activity]   = ('Your %s skill has increased'):fmt(SKILL_NAMES[activity]);
end

----------------------------------------
-- Settings
----------------------------------------

local default_settings = T{
    characters = T{},
    window     = T{
        auto_popup = true,
    },
};

local helm_settings = settings.load(default_settings);

settings.register('settings', 'settings_update', function(s)
    if (s ~= nil) then
        helm_settings = s;
    end
    settings.save();
end);

local state = T{
    show                 = false,
    debug                = false,
    last_activity        = nil,
    last_gather_activity = nil,
    last_gather_zone     = nil,
    last_gather_time     = 0,
};

----------------------------------------
-- Helpers
----------------------------------------

local function msg(text)
    print(chat.header(addon.name):append(chat.message(text)));
end

local function err(text)
    print(chat.header(addon.name):append(chat.error(text)));
end

local function get_char_name()
    local party = AshitaCore:GetMemoryManager():GetParty();
    if (party == nil) then return 'unknown'; end
    local name = party:GetMemberName(0);
    if (name == nil or name == '') then return 'unknown'; end
    return name;
end

local function get_current_zone_id()
    local party = AshitaCore:GetMemoryManager():GetParty();
    if (party == nil) then return 0; end
    return party:GetMemberZone(0) or 0;
end

local function get_zone_name(zoneId)
    local name = ZONE_NAMES[zoneId];
    if (name ~= nil) then return name; end

    local ok, resolved = pcall(function()
        return AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
    end);
    if (not ok or resolved == nil or resolved == '') then
        resolved = ('Zone %d'):fmt(zoneId);
    end

    ZONE_NAMES[zoneId] = resolved;
    return resolved;
end

local function match_activity(name)
    if (name == nil) then return nil; end
    for _, activity in ipairs(ACTIVITIES) do
        if (activity:lower() == name) then return activity; end
    end
    return nil;
end

local function get_fatigue_color(value)
    if (value >= FATIGUE_CAP) then
        return COLOR_HIGH;
    elseif (value >= FATIGUE_WARN) then
        return COLOR_MID;
    end
    return COLOR_LOW;
end

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

local function get_rarity_tier(pct)
    for _, tier in ipairs(RARITY_TIERS) do
        if (pct >= tier.min_pct) then return tier; end
    end
    return RARITY_TIERS[#RARITY_TIERS];
end

----------------------------------------
-- Data access
----------------------------------------

local function ensure_char(charname)
    local char = helm_settings.characters[charname];
    if (char == nil) then
        char = T{ fatigue = T{}, item_log = T{}, skill = T{}, skillups = T{},
                  attempts = T{}, successes = T{} };
        helm_settings.characters[charname] = char;
    end
    char.fatigue   = char.fatigue or T{};
    char.item_log  = char.item_log or T{};
    char.skill     = char.skill or T{};
    char.skillups  = char.skillups or T{};
    char.attempts  = char.attempts or T{};
    char.successes = char.successes or T{};
    return char;
end

local function ensure_fatigue(charname, activity)
    local char = ensure_char(charname);
    char.fatigue[activity] = char.fatigue[activity] or T{};
    return char.fatigue[activity];
end

local function ensure_item_log(charname, activity, zoneId)
    local char = ensure_char(charname);
    local key  = zone_key(zoneId);
    char.item_log[activity]      = char.item_log[activity] or T{};
    char.item_log[activity][key] = char.item_log[activity][key] or T{};
    return char.item_log[activity][key];
end

local function get_fatigue(charname, activity, zoneId)
    local char = helm_settings.characters[charname];
    if (char == nil or char.fatigue == nil or char.fatigue[activity] == nil) then
        return 0;
    end
    return char.fatigue[activity][zone_key(zoneId)] or 0;
end

local function set_fatigue(charname, activity, zoneId, value)
    ensure_fatigue(charname, activity)[zone_key(zoneId)] =
        math.max(0, math.min(FATIGUE_CAP, value));
end

local function get_skill(charname, activity)
    local char = helm_settings.characters[charname];
    if (char == nil or char.skill == nil) then return nil; end
    return char.skill[activity];
end

local function set_skill(charname, activity, value)
    ensure_char(charname).skill[activity] = value;
end

local function get_attempts(charname, activity, zoneId)
    local char = helm_settings.characters[charname];
    if (char == nil or char.attempts == nil or char.attempts[activity] == nil) then
        return 0;
    end
    return char.attempts[activity][zone_key(zoneId)] or 0;
end

local function get_successes(charname, activity, zoneId)
    local char = helm_settings.characters[charname];
    if (char == nil or char.successes == nil or char.successes[activity] == nil) then
        return 0;
    end
    return char.successes[activity][zone_key(zoneId)] or 0;
end

local function get_skillups(charname, activity, zoneId)
    local char = helm_settings.characters[charname];
    if (char == nil or char.skillups == nil or char.skillups[activity] == nil) then
        return 0;
    end
    return char.skillups[activity][zone_key(zoneId)] or 0;
end

local function get_item_log(charname, activity, zoneId)
    local char = helm_settings.characters[charname];
    if (char == nil or char.item_log == nil or char.item_log[activity] == nil) then
        return EMPTY_LOG;
    end
    return char.item_log[activity][zone_key(zoneId)] or EMPTY_LOG;
end

local function register_gather(activity, zoneId)
    local fatigue = ensure_fatigue(get_char_name(), activity);
    local key     = zone_key(zoneId);

    fatigue[key] = math.min(FATIGUE_CAP, (fatigue[key] or 0) + 1);

    for zid, value in pairs(fatigue) do
        if (zid ~= key) then
            fatigue[zid] = math.max(0, value - 1);
        end
    end
end

local function register_fatigue_cap(activity, zoneId)
    set_fatigue(get_char_name(), activity, zoneId, FATIGUE_CAP);
end

local function register_item_gather(activity, zoneId, itemName)
    if (itemName == nil) then return; end
    local log = ensure_item_log(get_char_name(), activity, zoneId);
    log[itemName] = (log[itemName] or 0) + 1;
end

local function register_skill(activity, value)
    set_skill(get_char_name(), activity, value);
end

local function register_attempt(activity, zoneId)
    local char = ensure_char(get_char_name());
    local key  = zone_key(zoneId);
    char.attempts[activity]      = char.attempts[activity] or T{};
    char.attempts[activity][key] = (char.attempts[activity][key] or 0) + 1;
end

local function register_success(activity, zoneId)
    local char = ensure_char(get_char_name());
    local key  = zone_key(zoneId);
    char.successes[activity]      = char.successes[activity] or T{};
    char.successes[activity][key] = (char.successes[activity][key] or 0) + 1;
end

local function register_skillup(activity, zoneId)
    local char = ensure_char(get_char_name());
    local key  = zone_key(zoneId);
    char.skillups[activity]      = char.skillups[activity] or T{};
    char.skillups[activity][key] = (char.skillups[activity][key] or 0) + 1;
end

local function reset_session()
    helm_settings.characters[get_char_name()] =
        T{ fatigue = T{}, item_log = T{}, skill = T{}, skillups = T{},
           attempts = T{}, successes = T{} };

    state.last_activity        = nil;
    state.last_gather_activity = nil;
    state.last_gather_zone     = nil;
    state.last_gather_time     = 0;

    settings.save();
end

----------------------------------------
-- Item names
----------------------------------------

local function extract_after(text, prefix)
    local _, stop = text:find(prefix, 1, true);
    if (stop == nil) then return nil; end

    local rest = text:sub(stop + 1):gsub('^%s+', ''):gsub('%s+$', ''):gsub('%.$', '');
    if (rest == '') then return nil; end
    return rest;
end

local function clean_item_name(name)
    if (name == nil) then return nil; end

    local comma = name:find(',', 1, true);
    if (comma ~= nil) then
        name = name:sub(1, comma - 1);
    end

    name = name:gsub("[^%w%s'%-]", '')
               :gsub('^%s+', '')
               :gsub('%s+$', '')
               :gsub('%s%s+', ' ');

    if (name == '') then return nil; end
    return name;
end

----------------------------------------
-- Detection
----------------------------------------

local function resolve_from(patterns, text, zoneId)
    local fallback_activity, fallback_pattern = nil, nil;

    for _, activity in ipairs(ACTIVITIES) do
        for _, pattern in ipairs(patterns[activity]) do
            if (text:find(pattern, 1, true)) then
                if (TRACKED_ZONE_SET[activity][zoneId]) then
                    return activity, pattern;
                end
                if (fallback_activity == nil) then
                    fallback_activity, fallback_pattern = activity, pattern;
                end
                break;
            end
        end
    end

    return fallback_activity, fallback_pattern;
end

local function resolve_gather(text, zoneId)
    return resolve_from(MESSAGE_PATTERNS, text, zoneId);
end

local function resolve_failure(text, zoneId)
    return resolve_from(FAILURE_PATTERNS, text, zoneId);
end

local function resolve_skill(text)
    if (not text:find(SKILL_MARKER, 1, true)) then return nil, nil; end

    for _, activity in ipairs(ACTIVITIES) do
        if (text:find(SKILL_PATTERNS[activity], 1, true)) then
            local value = tonumber(text:match(SKILL_VALUE_DECIMAL))
                       or tonumber(text:match(SKILL_VALUE_INTEGER));
            if (value ~= nil) then
                return activity, value;
            end
        end
    end
    return nil, nil;
end

----------------------------------------
-- Events
----------------------------------------

ashita.events.register('text_in', 'hhelmet_text_in', function(e)
    local text = e.message;
    if (text == nil or text == '' or e.injected) then return; end

    if (state.debug) then
        msg(('[mode %d] %s'):fmt(e.mode, text));
    end

    local zoneId = get_current_zone_id();

    local skill_activity, skill_value = resolve_skill(text);
    if (skill_activity ~= nil) then
        register_skill(skill_activity, skill_value);
        register_skillup(skill_activity, zoneId);
        settings.save();
        return;
    end

    local activity, matched = resolve_gather(text, zoneId);
    local failed = false;

    if (activity == nil) then
        activity = resolve_failure(text, zoneId);
        failed   = (activity ~= nil);
    end

    if (activity ~= nil) then
        state.last_activity = activity;

        local now = os.clock();
        if (activity == state.last_gather_activity
            and zoneId == state.last_gather_zone
            and (now - state.last_gather_time) < DEDUP_WINDOW_SECONDS) then
            if (state.debug) then
                msg('[dedup] ignored duplicate ' .. activity .. ' event');
            end
            return;
        end

        state.last_gather_activity = activity;
        state.last_gather_zone     = zoneId;
        state.last_gather_time     = now;

        register_attempt(activity, zoneId);

        if (not failed) then
            register_success(activity, zoneId);
            register_gather(activity, zoneId);

            if (TRACKED_ZONE_SET[activity][zoneId]) then
                register_item_gather(activity, zoneId, clean_item_name(extract_after(text, matched)));
            end
        end

        settings.save();

        if (helm_settings.window.auto_popup) then
            state.show = true;
        end
        return;
    end

    if (text:find(FATIGUE_PATTERN, 1, true)) then
        if (state.last_activity == nil) then
            if (state.debug) then
                err('Fatigue message matched but no activity has been attempted yet this session.');
            end
            return;
        end

        register_fatigue_cap(state.last_activity, zoneId);
        settings.save();

        if (helm_settings.window.auto_popup) then
            state.show = true;
        end
    end
end);

local function render_skill(charname, activity)
    local skill = get_skill(charname, activity);
    if (skill == nil) then
        imgui.TextDisabled(('%s skill: unknown'):fmt(activity));
    else
        imgui.Text(('%s skill: %.1f'):fmt(activity, skill));
    end
end

local function render_fatigue(charname, activity, zoneId, zoneName, curZoneId)
    local value = get_fatigue(charname, activity, zoneId);
    local color = get_fatigue_color(value);

    local label = zoneName;
    if (zoneId == curZoneId) then
        label = label .. '  (here)';
    end

    imgui.TextColored(color, ('%s: %d / %d'):fmt(label, value, FATIGUE_CAP));

    imgui.PushStyleColor(ImGuiCol_PlotHistogram, color);
    imgui.ProgressBar(value / FATIGUE_CAP, { -1, 14 }, '');
    imgui.PopStyleColor(1);

    if (value >= FATIGUE_CAP) then
        imgui.TextColored(COLOR_FATIGUED, 'FATIGUED');
    end

    imgui.Spacing();
end

local function count_gathers(log)
    local total = 0;
    for _, count in pairs(log) do
        total = total + count;
    end
    return total;
end

local function render_item_list(log, total)
    if (total == 0) then
        imgui.TextDisabled('  No gathers recorded yet.');
        return;
    end

    local items = T{};
    for itemName, count in pairs(log) do
        local pct = count / total * 100;
        table.insert(items, {
            name  = itemName,
            count = count,
            pct   = pct,
            tier  = get_rarity_tier(pct),
        });
    end

    table.sort(items, function(a, b)
        if (a.tier.rank ~= b.tier.rank) then
            return a.tier.rank < b.tier.rank;
        end
        return a.name < b.name;
    end);

    local last_rank = nil;
    for _, item in ipairs(items) do
        if (item.tier.rank ~= last_rank) then
            imgui.Spacing();
            imgui.TextDisabled(item.tier.name);
            last_rank = item.tier.rank;
        end
        imgui.Text(('    %s: %d  (%.1f%%)'):fmt(item.name, item.count, item.pct));
    end
end

local function render_home(charname, curZoneId)
    local activities = ZONE_ACTIVITIES[curZoneId];

    imgui.Spacing();
    if (activities == nil or #activities == 0) then
        imgui.TextDisabled('No HELM activity is tracked in this zone.');
        imgui.Spacing();
        return;
    end

    local zoneName = get_zone_name(curZoneId);

    for index, activity in ipairs(activities) do
        if (index > 1) then
            imgui.Separator();
            imgui.Spacing();
        end

        imgui.Text(activity);
        render_skill(charname, activity);
        imgui.Spacing();

        render_fatigue(charname, activity, curZoneId, zoneName, curZoneId);

        local log       = get_item_log(charname, activity, curZoneId);
        local total     = count_gathers(log);
        local attempts  = get_attempts(charname, activity, curZoneId);
        local successes = get_successes(charname, activity, curZoneId);

        local skillups = get_skillups(charname, activity, curZoneId);

        if (attempts > 0) then
            imgui.TextDisabled(('Gathers %d/%d (%.1f%%)   Skill ups %d/%d (%.1f%%)')
                :fmt(successes, attempts, successes / attempts * 100,
                     skillups,  attempts, skillups  / attempts * 100));
        else
            imgui.TextDisabled(('Gathers 0/0   Skill ups %d/0'):fmt(skillups));
        end

        imgui.Spacing();
        imgui.TextDisabled(('Items  -  %d logged'):fmt(total));
        render_item_list(log, total);
        imgui.Spacing();
    end
end

local function render_settings(charname)
    imgui.Spacing();
    imgui.TextDisabled('Skill levels');
    imgui.Spacing();

    imgui.PushItemWidth(SKILL_INPUT_WIDTH);
    for _, activity in ipairs(ACTIVITIES) do
        local buffer = { get_skill(charname, activity) or 0 };
        if (imgui.InputFloat(activity, buffer, 0, 0, '%.1f')) then
            set_skill(charname, activity, math.max(0, buffer[1]));
            settings.save();
        end
    end
    imgui.PopItemWidth();

    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();

    if (imgui.Checkbox('Auto-open on gather', { helm_settings.window.auto_popup })) then
        helm_settings.window.auto_popup = not helm_settings.window.auto_popup;
        settings.save();
    end

    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();

    if (imgui.Button('Reset Session')) then
        reset_session();
    end
    imgui.TextDisabled('Clears all personal data for this character.');

    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();
    imgui.TextDisabled('Exporting Coming Soon');
    imgui.Spacing();
end

ashita.events.register('d3d_present', 'hhelmet_present', function()
    if (not state.show) then return; end

    local charname  = get_char_name();
    local curZoneId = get_current_zone_id();

    imgui.SetNextWindowSize({ 360, 0, }, ImGuiCond_FirstUseEver);

    local isOpen = { state.show };
    if (imgui.Begin('HHelmet', isOpen, ImGuiWindowFlags_AlwaysAutoResize)) then
        imgui.Text(('Character: %s'):fmt(charname));
        imgui.Text(('Current zone: %s'):fmt(get_zone_name(curZoneId)));
        imgui.Separator();

        if (imgui.BeginTabBar('##hhelmet_activity_tabs')) then
            if (imgui.BeginTabItem('Home')) then
                render_home(charname, curZoneId);
                imgui.EndTabItem();
            end

            for _, activity in ipairs(ACTIVITIES) do
                if (imgui.BeginTabItem(activity)) then
                    local zones = TRACKED_ZONES[activity];

                    render_skill(charname, activity);
                    imgui.Separator();
                    imgui.Spacing();

                    for _, zone in ipairs(zones) do
                        render_fatigue(charname, activity, zone.id, zone.name, curZoneId);
                    end

                    imgui.Separator();
                    imgui.TextDisabled('Item drop tracking');
                    imgui.Spacing();

                    for _, zone in ipairs(zones) do
                        local log   = get_item_log(charname, activity, zone.id);
                        local total = count_gathers(log);

                        local heading = zone.name;
                        if (zone.id == curZoneId) then
                            heading = heading .. '  (here)';
                        end
                        heading = ('%s  -  %d gathers'):fmt(heading, total);

                        if (imgui.CollapsingHeader(heading)) then
                            render_item_list(log, total);
                            imgui.Spacing();
                        end
                    end

                    imgui.EndTabItem();
                end
            end

            if (imgui.BeginTabItem('Settings')) then
                render_settings(charname);
                imgui.EndTabItem();
            end

            imgui.EndTabBar();
        end
    end
    imgui.End();

    state.show = isOpen[1];
end);

ashita.events.register('command', 'hhelmet_command', function(e)
    local args = e.command:args();
    if (#args == 0 or args[1]:lower() ~= '/hhelmet') then return; end

    e.blocked = true;

    local sub      = args[2] and args[2]:lower() or nil;
    local charname = get_char_name();
    local zoneId   = get_current_zone_id();

    if (sub == nil) then
        state.show = not state.show;

    elseif (sub == 'show') then
        state.show = true;

    elseif (sub == 'hide') then
        state.show = false;

    elseif (sub == 'debug') then
        state.debug = not state.debug;
        msg('Debug printing ' .. (state.debug and 'enabled' or 'disabled') .. '.');

    elseif (sub == 'reset') then
        local target = args[3] and args[3]:lower() or nil;

        if (target == 'all') then
            reset_session();
            msg('All fatigue data reset for ' .. charname .. '.');

        elseif (target == nil) then
            msg('Usage: /hhelmet reset <all|activity> [zone]');

        else
            local activity = match_activity(target);
            if (activity == nil) then
                err('Unknown activity. Use: Harvesting, Excavation, Logging, or Mining.');
            elseif (args[4] and args[4]:lower() == 'zone') then
                set_fatigue(charname, activity, zoneId, 0);
                settings.save();
                msg(('%s fatigue reset for %s in %s.'):fmt(activity, charname, get_zone_name(zoneId)));
            else
                ensure_char(charname).fatigue[activity] = T{};
                settings.save();
                msg(('%s fatigue reset for %s (all zones).'):fmt(activity, charname));
            end
        end

    elseif (sub == 'set') then
        local activity = match_activity(args[3] and args[3]:lower() or nil);
        local value    = tonumber(args[4]);

        if (activity == nil or value == nil) then
            msg('Usage: /hhelmet set <activity> <0-200>');
        else
            set_fatigue(charname, activity, zoneId, value);
            settings.save();
            msg(('%s fatigue in %s set to %d.'):fmt(activity, get_zone_name(zoneId), value));
        end

    elseif (sub == 'skill') then
        local activity = match_activity(args[3] and args[3]:lower() or nil);
        local value    = tonumber(args[4]);

        if (activity == nil or value == nil or value < 0) then
            msg('Usage: /hhelmet skill <activity> <value>');
        else
            set_skill(charname, activity, value);
            settings.save();
            msg(('%s skill set to %.1f.'):fmt(activity, value));
        end

    else
        msg('Usage: /hhelmet [show|hide|debug|reset <all|activity> [zone]|set <activity> <0-200>|skill <activity> <value>]');
    end
end);

ashita.events.register('load', 'hhelmet_load', function()
    msg(('v%s loaded. Use /hhelmet debug to calibrate message detection.'):fmt(addon.version));
end);

ashita.events.register('unload', 'hhelmet_unload', function()
    settings.save();
end);

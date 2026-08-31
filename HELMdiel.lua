addon.name    = 'HELMdiel';
addon.author  = 'Masuru';
addon.version = '0.14.3';
addon.desc    = 'Tracks HELM (Harvesting/Excavation/Logging/Mining) regional gathering fatigue on HorizonXI.';
addon.link    = 'https://github.com/KisamMeow/HELMdiel';

require('common');
local chat     = require('chat');

local data      = require('data');
local resources = require('resources');
local store     = require('store');
local detect    = require('detect');
local export    = require('export');
local ui        = require('ui');


----------------------------------------
-- Helpers
----------------------------------------

local state = T{
    show                 = false,
    debug                = false,
    last_activity        = nil,
    last_gather_activity = nil,
    last_gather_zone     = nil,
    last_gather_time     = 0,
    repeat_activity      = nil,
    repeat_zone          = nil,
    repeat_item          = nil,
    repeat_node          = nil,
    repeat_node_index    = nil,
    repeat_time          = 0,
    node_index           = nil,
    node_id              = nil,
    node_time            = 0,
};

local recent_break       = {};
local recent_proc        = {};
local recent_skill_value = {};
local recent_skill_time  = {};

local function repeated(seen, key, now)
    local last = seen[key];
    seen[key] = now;
    return last ~= nil and (now - last) < data.DEDUP_WINDOW_SECONDS;
end

local function repeated_skill(activity, value, now)
    local same = recent_skill_value[activity] == value
             and recent_skill_time[activity] ~= nil
             and (now - recent_skill_time[activity]) < data.DEDUP_WINDOW_SECONDS;

    recent_skill_value[activity] = value;
    recent_skill_time[activity]  = now;
    return same;
end

local function msg(text)
    print(chat.header(addon.name):append(chat.message(text)));
end

local function err(text)
    print(chat.header(addon.name):append(chat.error(text)));
end


local function match_activity(name)
    if (name == nil) then return nil; end
    for _, activity in ipairs(data.ACTIVITIES) do
        if (activity:lower() == name) then return activity; end
    end
    return nil;
end

----------------------------------------
-- Events
----------------------------------------

local function clear_run()
    state.repeat_activity = nil;
    state.repeat_zone     = nil;
    state.repeat_item     = nil;
    state.repeat_node     = nil;
    state.repeat_node_index = nil;
end

-- The packet describes one swing. Reading it later would let a swing the
-- hook missed inherit the node before it, which is the silent misread this
-- whole change exists to remove.
local function node_now(now)
    if ((now - state.node_time) >= data.NODE_WINDOW_SECONDS) then return nil; end
    return state.node_id;
end

local function same_node()
    return state.repeat_node ~= nil and node_now(os.clock()) == state.repeat_node;
end

local function in_run(activity, zoneId, item, now)
    if (state.repeat_activity ~= activity or state.repeat_zone ~= zoneId) then
        return false;
    end
    if ((now - state.repeat_time) >= data.REPEAT_WINDOW_SECONDS) then
        return false;
    end
    local at = node_now(now);
    if (state.repeat_node ~= nil and at ~= nil) then
        return at == state.repeat_node;
    end
    if (state.repeat_node ~= nil and state.repeat_node_index ~= nil
        and resources.node_gone(state.repeat_node_index, state.repeat_node)) then
        return false;
    end
    return state.repeat_item == nil or state.repeat_item == item;
end

ashita.events.register('packet_out', 'helmdiel_packet_out', function(e)
    if (e.id ~= data.HELM_PACKET) then return; end

    local index, serverId = resources.target_node();
    if (index == nil or serverId == nil) then
        state.node_index, state.node_id = nil, nil;
        state.node_time = 0;
        if (state.debug) then msg('[node] a HELM swing at an unknown target'); end
        return;
    end

    state.node_index, state.node_id = index, serverId;
    state.node_time = os.clock();
    if (state.debug) then
        msg(('[node] swing at node %d (index %d)'):fmt(serverId, index));
    end
end);

ashita.events.register('text_in', 'helmdiel_text_in', function(e)
    local text = e.message;
    if (text == nil or text == '' or e.injected) then return; end

    local mode = (e.mode or 0) % data.CHAT_MODE_MASK;
    local helm = data.HELM_CHAT_MODES[mode] == true;
    if (not helm and not state.debug) then return; end

    if (detect.has_codes(text)) then
        text = detect.strip_codes(text);
    end

    if (state.debug) then
        msg(('[mode %d raw %d]%s %s')
            :fmt(mode, e.mode or 0, helm and '' or ' dropped', text));
    end

    if (not helm) then return; end

    local zoneId = store.zone_id();
    local now    = os.clock();

    local skill_activity, skill_value = detect.skill(text);
    if (skill_activity ~= nil) then
        if (repeated_skill(skill_activity, skill_value, now)) then
            if (state.debug) then
                msg(('[dedup] ignored a repeat %s skill up at %.1f')
                    :fmt(skill_activity, skill_value));
            end
            return;
        end

        store.register_skill(skill_activity, skill_value);
        store.register_skillup(skill_activity, zoneId);
        store.register_moon_skillup(skill_activity, resources.moon_phase());
        store.reset_since_skillup(skill_activity);
        store.save();
        return;
    end

    local broke = detect.tool_break(text, zoneId);
    if (broke ~= nil and not repeated(recent_break, broke, now)) then
        store.register_break(broke, zoneId);
        if (state.debug) then msg(('[break] counted a %s tool break'):fmt(broke)); end
    end

    local proc_activity, proc_name = detect.proc(text, zoneId);
    if (proc_name ~= nil) then
        state.last_activity = proc_activity;

        if (not repeated(recent_proc, proc_name, now)) then
            store.register_proc(proc_name, zoneId);
            store.save();
            if (state.debug) then msg(('[proc] counted %s'):fmt(proc_name)); end
        end

        if (data.PROC_REPEATS[proc_name]) then
            state.repeat_activity = proc_activity;
            state.repeat_zone     = zoneId;
            state.repeat_item     = nil;
            state.repeat_node       = node_now(now);
            state.repeat_node_index = state.node_index;
            state.repeat_time     = now;
        end
        return;
    end

    local activity, matched = detect.gather(text, zoneId);
    local failed = false;
    local barren = false;

    if (activity == nil) then
        activity = detect.barren(text, zoneId);
        if (activity ~= nil) then
            barren = true;
            failed = true;
        end
    end

    if (activity == nil) then
        activity = detect.failure(text, zoneId);
        failed   = (activity ~= nil);
    end

    if (activity ~= nil) then
        state.last_activity = activity;

        local since = now - state.last_gather_time;

        if (activity == state.last_gather_activity
            and zoneId == state.last_gather_zone
            and since < data.DEDUP_WINDOW_SECONDS) then
            if (state.debug and since >= data.DEDUP_QUIET_SECONDS) then
                msg(('[dedup] ignored %s event %.2fs after the last one')
                    :fmt(activity, since));
            end
            return;
        end

        if (state.debug and activity == state.last_gather_activity
            and zoneId == state.last_gather_zone) then
            msg(('[dedup] counted %s event %.2fs after the last one')
                :fmt(activity, since));
        end

        state.last_gather_activity = activity;
        state.last_gather_zone     = zoneId;
        state.last_gather_time     = now;

        local blocked = failed
            and store.is_fatigued(store.char_name(), activity, zoneId);

        if (not blocked) then
            store.register_attempt(activity, zoneId);

            if (store.skill_capped(store.char_name(), activity, zoneId) == nil) then
                store.bump_since_skillup(activity);

                local phase = resources.moon_phase();
                store.register_moon_swing(activity, phase);
                if (state.debug) then
                    msg(('[moon] swing under %s')
                        :fmt(phase or 'no readable game clock'));
                end
            elseif (state.debug) then
                msg(('[capped] %s swing where skill cannot rise, not counted'
                     .. ' towards the swings since your last skill up'):fmt(activity));
            end
        elseif (state.debug) then
            msg(('[fatigued] %s swing in a capped zone, not counted'):fmt(activity));
        end

        if (not failed) then
            store.register_success(activity, zoneId);
            store.register_gather(activity, zoneId);

            local item = detect.clean_item_name(detect.extract_after(text, matched));

            local repeated = in_run(activity, zoneId, item, now);

            if (repeated) then
                state.repeat_item = item;
                state.repeat_time = now;
                if (state.debug) then
                    msg(('[repeat] %s from Gold Rush node %s, %s'):fmt(item,
                        state.repeat_node and tostring(state.repeat_node) or 'unknown',
                        store.count_repeats() and 'counted' or 'not counted'));
                end
            else
                clear_run();
            end

            if (data.TRACKED_ZONE_SET[activity][zoneId]) then
                store.register_item_gather(activity, zoneId, item, repeated);

                if (store.auto_show() and store.reveal_activity(activity)) then
                    msg(('%s was hidden and is showing again.'):fmt(activity));
                end
            end
        else
            if (not same_node()) then clear_run(); end

            if (barren) then store.register_gather(activity, zoneId); end
        end

        store.save();

        if (store.auto_popup()) then
            ui.visible = true;
        end
        return;
    end

    if (detect.is_fatigue_message(text)) then
        local activity = detect.fatigued_activity(zoneId, state.last_activity);
        if (activity == nil) then
            if (state.debug) then
                err('Fatigue message matched but could not be attributed to an activity.');
            end
            return;
        end

        store.register_fatigue_cap(activity, zoneId);
        store.save();

        if (store.auto_popup()) then
            ui.visible = true;
        end
    end
end);

local function clear_detection_state()
    state.last_activity        = nil;
    state.last_gather_activity = nil;
    state.last_gather_zone     = nil;
    state.last_gather_time     = 0;
    state.repeat_activity      = nil;
    state.repeat_zone          = nil;
    state.repeat_item          = nil;
    state.repeat_node          = nil;
    state.repeat_node_index    = nil;
    state.repeat_time          = 0;
    state.node_index           = nil;
    state.node_id              = nil;
    state.node_time            = 0;

    recent_break       = {};
    recent_proc        = {};
    recent_skill_value = {};
    recent_skill_time  = {};
end

local function reset_session()
    store.reset_session();
    clear_detection_state();
end

local function reset_all()
    store.reset_all();
    clear_detection_state();
end

local function export_csv()
    local ok, path, rows = export.write(store.char_name());
    if (ok) then
        msg(('Exported %d rows to %s'):fmt(rows, path));
    else
        err(('Could not write %s'):fmt(path));
    end
end

ui.set_actions(T{ reset_session = reset_session, reset_all = reset_all,
                  export = export_csv });
ui.set_title(addon.version);

ashita.events.register('d3d_present', 'helmdiel_present', function()
    ui.render(store.player());
end);

ashita.events.register('command', 'helmdiel_command', function(e)
    local args = e.command:args();
    if (#args == 0) then return; end

    local entered = args[1]:lower();
    if (entered ~= '/helmdiel' and entered ~= '/hd') then return; end

    e.blocked = true;

    local sub      = args[2] and args[2]:lower() or nil;
    local charname = store.char_name();
    local zoneId   = store.zone_id();

    if (sub == nil) then
        ui.visible = not ui.visible;

    elseif (sub == 'show') then
        ui.visible = true;

    elseif (sub == 'hide') then
        ui.visible = false;

    elseif (sub == 'debug') then
        state.debug = not state.debug;
        msg('Debug printing ' .. (state.debug and 'enabled' or 'disabled') .. '.');

    elseif (sub == 'names') then
        local wrong = 0;
        for _, activity in ipairs(data.ACTIVITIES) do
            for zoneId, entries in pairs(data.ZONE_ITEMS[activity] or T{}) do
                for _, entry in ipairs(entries) do
                    local shown = resources.item_name(entry.name);
                    if (shown ~= entry.name) then
                        wrong = wrong + 1;
                        msg(('%s %s: %s -> %s')
                            :fmt(activity, resources.zone_name(zoneId),
                                 entry.name, shown));
                    end
                end
            end
        end
        msg(('%d name%s differ from the inventory spelling.')
            :fmt(wrong, wrong == 1 and '' or 's'));

    elseif (sub == 'reset') then
        local target = args[3] and args[3]:lower() or nil;

        if (target == 'all') then
            reset_all();
            msg('All data reset for ' .. charname .. '.');

        elseif (target == nil) then
            msg('Usage: /helmdiel reset <all|activity> [zone]');

        else
            local activity = match_activity(target);
            if (activity == nil) then
                err('Unknown activity. Use: Harvesting, Excavation, Logging, or Mining.');
            elseif (args[4] and args[4]:lower() == 'zone') then
                store.set_fatigue(charname, activity, zoneId, 0);
                store.save();
                msg(('%s fatigue reset for %s in %s.'):fmt(activity, charname, resources.zone_name(zoneId)));
            else
                store.reset_activity(charname, activity);
                store.save();
                msg(('%s fatigue reset for %s (all zones).'):fmt(activity, charname));
            end
        end

    elseif (sub == 'set') then
        local activity = match_activity(args[3] and args[3]:lower() or nil);
        local value    = tonumber(args[4]);

        if (activity == nil or value == nil) then
            msg('Usage: /helmdiel set <activity> <value>');
        else
            store.set_fatigue(charname, activity, zoneId, value);
            store.save();
            msg(('%s fatigue in %s set to %d.'):fmt(activity, resources.zone_name(zoneId), value));
        end

    elseif (sub == 'skill') then
        local activity = match_activity(args[3] and args[3]:lower() or nil);
        local value    = tonumber(args[4]);

        if (activity == nil or value == nil or value < 0) then
            msg('Usage: /helmdiel skill <activity> <value>');
        else
            store.set_skill(charname, activity, value);
            store.save();
            msg(('%s skill set to %.1f.'):fmt(activity, value));
        end

    else
        msg('Usage: /helmdiel or /hd [show|hide|debug|names|reset <all|activity> [zone]|set <activity> <value>|skill <activity> <value>]');
    end
end);

ashita.events.register('load', 'helmdiel_load', function()
    if (not ui.load_font()) then
        err(('Could not load %s. Using the default font.'):fmt(data.FONT_PATH));
    end
    msg(('v%s loaded. Use /helmdiel debug to calibrate message detection.'):fmt(addon.version));
end);

ashita.events.register('unload', 'helmdiel_unload', function()
    store.save();
end);

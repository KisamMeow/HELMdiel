addon.name    = 'HELMdiel';
addon.author  = 'Masuru';
addon.version = '0.9.1';
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
};

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

ashita.events.register('text_in', 'helmdiel_text_in', function(e)
    local text = e.message;
    if (text == nil or text == '' or e.injected) then return; end

    if (state.debug) then
        msg(('[mode %d] %s'):fmt(e.mode, text));
    end

    local zoneId = store.zone_id();

    local skill_activity, skill_value = detect.skill(text);
    if (skill_activity ~= nil) then
        store.register_skill(skill_activity, skill_value);
        store.register_skillup(skill_activity, zoneId);
        store.save();
        return;
    end

    local activity, matched = detect.gather(text, zoneId);
    local failed = false;

    if (activity == nil) then
        activity = detect.failure(text, zoneId);
        failed   = (activity ~= nil);
    end

    if (activity ~= nil) then
        state.last_activity = activity;

        local now = os.clock();
        if (activity == state.last_gather_activity
            and zoneId == state.last_gather_zone
            and (now - state.last_gather_time) < data.DEDUP_WINDOW_SECONDS) then
            if (state.debug) then
                msg('[dedup] ignored duplicate ' .. activity .. ' event');
            end
            return;
        end

        state.last_gather_activity = activity;
        state.last_gather_zone     = zoneId;
        state.last_gather_time     = now;

        store.register_attempt(activity, zoneId);

        if (not failed) then
            store.register_success(activity, zoneId);
            store.register_gather(activity, zoneId);

            if (data.TRACKED_ZONE_SET[activity][zoneId]) then
                store.register_item_gather(activity, zoneId, detect.clean_item_name(detect.extract_after(text, matched)));
            end
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
end

local function reset_session()
    store.reset_session();
    clear_detection_state();
end

local function reset_all()
    store.reset_all();
    clear_detection_state();
end

-- Reported here rather than in ui, which owns no way to talk to the player.
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
    if (#args == 0 or args[1]:lower() ~= '/helmdiel') then return; end

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
            msg('Usage: /helmdiel set <activity> <0-200>');
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
        msg('Usage: /helmdiel [show|hide|debug|reset <all|activity> [zone]|set <activity> <0-200>|skill <activity> <value>]');
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

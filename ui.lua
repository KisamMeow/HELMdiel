require('common');

local imgui     = require('imgui');
local data      = require('data');
local store     = require('store');
local resources = require('resources');

local ui = T{};

local actions = T{};

function ui.set_actions(handlers)
    actions = handlers;
end

local function get_fatigue_color(value)
    if (value >= data.FATIGUE_CAP) then
        return data.COLOR_HIGH;
    elseif (value >= data.FATIGUE_WARN) then
        return data.COLOR_MID;
    end
    return data.COLOR_LOW;
end

local function get_rarity_tier(pct)
    for _, tier in ipairs(data.RARITY_TIERS) do
        if (pct >= tier.min_pct) then return tier; end
    end
    return data.RARITY_TIERS[#data.RARITY_TIERS];
end

local function render_skill(charname, activity)
    local skill = store.get_skill(charname, activity);
    if (skill == nil) then
        imgui.TextDisabled(('%s Skill: unknown'):fmt(activity));
    else
        imgui.Text(('%s Skill: %.1f'):fmt(activity, skill));
    end
end

local function render_fatigue(charname, activity, zoneId, zoneName)
    local value = store.get_fatigue(charname, activity, zoneId);
    local color = get_fatigue_color(value);

    imgui.TextColored(color, ('%s: %d / %d'):fmt(zoneName, value, data.FATIGUE_CAP));

    imgui.PushStyleColor(ImGuiCol_PlotHistogram, color);
    imgui.ProgressBar(value / data.FATIGUE_CAP, { -1, 14 }, '');
    imgui.PopStyleColor(1);

    if (store.is_fatigued(charname, activity, zoneId)) then
        imgui.TextColored(data.COLOR_FATIGUED, 'FATIGUED');
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
            name  = resources.item_name(itemName),
            count = count,
            pct   = pct,
            tier  = get_rarity_tier(pct),
        });
    end

    table.sort(items, function(a, b)
        if (a.count ~= b.count) then
            return a.count > b.count;
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

local function divider()
    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();
end

local function render_activity(charname, activity, curZoneId, zoneName)
    render_skill(charname, activity);
    imgui.Spacing();

    if (store.get_fatigue(charname, activity, curZoneId) > 0) then
        render_fatigue(charname, activity, curZoneId, zoneName);
    end

    if (store.home_minimum()) then return; end

    local log       = store.get_item_log(charname, activity, curZoneId);
    local total     = count_gathers(log);
    local attempts  = store.get_attempts(charname, activity, curZoneId);
    local successes = store.get_successes(charname, activity, curZoneId);
    local skillups  = store.get_skillups(charname, activity, curZoneId);

    if (attempts > 0) then
        imgui.TextDisabled(('Gathers - %d/%d (%.1f%%)')
            :fmt(successes, attempts, successes / attempts * 100));
        imgui.TextDisabled(('Skill Ups - %d/%d (%.1f%%)')
            :fmt(skillups, attempts, skillups / attempts * 100));
    else
        imgui.TextDisabled('Gathers 0/0');
        imgui.TextDisabled(('Skill Ups %d/0'):fmt(skillups));
    end

    imgui.Spacing();
    imgui.TextDisabled(('Items  -  %d logged'):fmt(total));
    render_item_list(log, total);
    imgui.Spacing();
end

local function render_home(charname, curZoneId)
    local tracked = data.ZONE_ACTIVITIES[curZoneId];

    imgui.Spacing();
    if (tracked == nil or #tracked == 0) then
        imgui.TextDisabled('No HELM activity is tracked in this zone.');
        imgui.Spacing();
        return;
    end

    local zoneName = resources.zone_name(curZoneId);
    local shown    = 0;

    for _, activity in ipairs(tracked) do
        if (store.activity_enabled(activity)) then
            shown = shown + 1;
            if (shown > 1) then
                imgui.Separator();
                imgui.Spacing();
            end

            render_activity(charname, activity, curZoneId, zoneName);
        end
    end

    if (shown == 0) then
        imgui.TextDisabled('All activities here are hidden.');
        imgui.Spacing();
    end
end

local function render_activity_tab(charname, activity)
    local zones = data.TRACKED_ZONES[activity];

    render_skill(charname, activity);
    imgui.Separator();
    imgui.Spacing();

    local fatigued = 0;
    for _, zone in ipairs(zones) do
        if (store.get_fatigue(charname, activity, zone.id) > 0) then
            render_fatigue(charname, activity, zone.id, zone.name);
            fatigued = fatigued + 1;
        end
    end

    if (fatigued == 0) then
        imgui.TextDisabled('No fatigue recorded.');
        imgui.Spacing();
    end

    imgui.Separator();
    imgui.TextDisabled('Item Tracking');
    imgui.Spacing();

    for _, zone in ipairs(zones) do
        if (imgui.CollapsingHeader(zone.name)) then
            local log   = store.get_item_log(charname, activity, zone.id);
            local total = count_gathers(log);

            if (total > 0) then
                imgui.TextDisabled(('%d Gathers'):fmt(total));
            end
            render_item_list(log, total);
            imgui.Spacing();
        end
    end
end

local function render_settings(charname)
    imgui.Spacing();

    if (imgui.Checkbox('Home Minimum Mode', { store.home_minimum() })) then
        store.toggle_home_minimum();
    end
    imgui.TextDisabled('Home shows only skill and fatigue.');

    divider();
    imgui.TextDisabled('Shown activities');
    imgui.Spacing();

    for _, activity in ipairs(data.ACTIVITIES) do
        if (imgui.Checkbox(('%s##show'):fmt(activity), { store.activity_enabled(activity) })) then
            store.toggle_activity(activity);
        end
    end

    divider();
    imgui.TextDisabled('Skill levels');
    imgui.Spacing();

    imgui.PushItemWidth(data.SKILL_INPUT_WIDTH);
    for _, activity in ipairs(data.ACTIVITIES) do
        local buffer = { store.get_skill(charname, activity) or 0 };
        if (imgui.InputFloat(activity, buffer, 0, 0, '%.1f')) then
            store.set_skill(charname, activity, math.max(0, buffer[1]));
            store.save();
        end
    end
    imgui.PopItemWidth();

    divider();

    if (imgui.Checkbox('Auto-open on gather', { store.auto_popup() })) then
        store.toggle_auto_popup();
    end

    divider();

    if (imgui.Button('Reset Session')) then
        actions.reset_session();
    end
    imgui.TextDisabled('Clears gather and skill up counters.');

    imgui.Spacing();

    if (imgui.Button('Reset All Data')) then
        actions.reset_all();
    end
    imgui.TextDisabled('Clears everything for this character.');

    divider();
    imgui.TextDisabled('Exporting Coming Soon');
    imgui.Spacing();
end


function ui.render(charname, curZoneId)
    resources.scan_chunk();

    if (not ui.visible) then return; end


    imgui.SetNextWindowSize({ 360, 0, }, ImGuiCond_FirstUseEver);

    local isOpen = { ui.visible };
    if (imgui.Begin('HHelmet', isOpen, ImGuiWindowFlags_AlwaysAutoResize)) then
        imgui.Text(('Character: %s'):fmt(charname));
        imgui.Text(('Current Zone: %s'):fmt(resources.zone_name(curZoneId)));
        imgui.Separator();

        if (imgui.BeginTabBar('##hhelmet_activity_tabs')) then
            if (imgui.BeginTabItem('Home')) then
                render_home(charname, curZoneId);
                imgui.EndTabItem();
            end

            for _, activity in ipairs(data.ACTIVITIES) do
                if (store.activity_enabled(activity) and imgui.BeginTabItem(activity)) then
                    render_activity_tab(charname, activity);
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

    ui.visible = isOpen[1];
end

return ui;

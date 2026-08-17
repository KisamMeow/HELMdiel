require('common');

local imgui     = require('imgui');
local data      = require('data');
local store     = require('store');
local resources = require('resources');
local icons     = require('icons');

local ui = T{};

ui.visible    = false;
ui.active_tab = 'Home';

local actions = T{};

local WINDOW_BG = { 0, 0, 0, 1 };

local scale = 1.0;

local function px(value)
    return value * scale;
end

local cell_id = 0;

-- Reused per-frame scratch
local ITEMS = T{};
local SLOTS = {};

local function item_slot(index)
    local slot = SLOTS[index];
    if (slot == nil) then
        slot = {};
        SLOTS[index] = slot;
    end
    return slot;
end

local function by_count_then_name(a, b)
    if (a.count ~= b.count) then return a.count > b.count; end
    return a.name < b.name;
end

local function by_name(a, b)
    return a.name < b.name;
end

local CELL_IDS = {};

local function next_cell_id()
    cell_id = cell_id + 1;
    local id = CELL_IDS[cell_id];
    if (id == nil) then
        id = ('##hhitem%d'):fmt(cell_id);
        CELL_IDS[cell_id] = id;
    end
    return id;
end

local NAV_LABELS = {};

local function nav_label(name)
    local label = NAV_LABELS[name];
    if (label == nil) then
        label = ('%s##nav'):fmt(name);
        NAV_LABELS[name] = label;
    end
    return label;
end

local SPOILS      = T{};
local SPOIL_SLOTS = {};

local function spoil_slot(index)
    local slot = SPOIL_SLOTS[index];
    if (slot == nil) then
        slot = {};
        SPOIL_SLOTS[index] = slot;
    end
    return slot;
end

local FIRST_SIZE = { 360, 0 };
local IS_OPEN    = { false };
local TABS       = T{};
local SPOIL_ICON = { 0, 0 };
local CELL_PAD   = { 0, 0 };
local BOX_SIZE   = { 0, 0 };
local ART_SIZE   = { 0, 0 };
local LINE_GAP   = { 0, 0 };

local STYLE_COLORS;
local STYLE_VARS;

local function window_style()
    if (STYLE_COLORS ~= nil) then return; end

    STYLE_COLORS = T{
        { ImGuiCol_WindowBg,         WINDOW_BG },
        { ImGuiCol_TitleBg,          WINDOW_BG },
        { ImGuiCol_TitleBgActive,    WINDOW_BG },
        { ImGuiCol_TitleBgCollapsed, WINDOW_BG },
        { ImGuiCol_TextDisabled,     data.COLOR_GOLD },

        { ImGuiCol_ResizeGrip,        data.COLOR_GRIP },
        { ImGuiCol_ResizeGripHovered, data.COLOR_GRIP_HOVER },
        { ImGuiCol_ResizeGripActive,  data.COLOR_GRIP_ACTIVE },

        { ImGuiCol_Button,        data.COLOR_BUTTON },
        { ImGuiCol_ButtonHovered, data.COLOR_BUTTON_HOVER },
        { ImGuiCol_ButtonActive,  data.COLOR_BUTTON_ACTIVE },

        { ImGuiCol_Header,        data.COLOR_HEADER },
        { ImGuiCol_HeaderHovered, data.COLOR_HEADER_HOVER },
        { ImGuiCol_HeaderActive,  data.COLOR_HEADER_ACTIVE },
    };

    STYLE_VARS = T{
        { ImGuiStyleVar_WindowRounding,   data.WINDOW_ROUNDING },
        { ImGuiStyleVar_WindowTitleAlign, data.TITLE_ALIGN },
        { ImGuiStyleVar_FrameRounding,    data.FRAME_ROUNDING },
    };
end

local title = 'HELMdiel###HELMdiel';

local font = nil;

function ui.load_font()
    if (font ~= nil) then return true; end

    local ok, loaded = pcall(imgui.AddFontFromFileTTF, data.FONT_PATH, data.FONT_SIZE);
    if (ok and loaded ~= nil) then
        font = loaded;
        return true;
    end
    return false;
end

function ui.set_actions(handlers)
    actions = handlers;
end

function ui.set_title(version)
    title = ('HELMdiel v%s###HELMdiel'):fmt(version);
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

local function render_skill(charname, activity, zoneId)
    local skill = store.get_skill(charname, activity);
    if (skill == nil) then
        imgui.TextDisabled(('%s Skill: unknown'):fmt(activity));
    else
        imgui.Text(('%s Skill: %.1f'):fmt(activity, skill));
    end

    if (zoneId == nil) then return; end

    local ups   = store.get_skillups(charname, activity, zoneId);
    local swings = store.get_attempts(charname, activity, zoneId);

    imgui.SameLine(0, px(data.CELL_GUTTER));
    if (swings > 0) then
        imgui.TextColored(data.COLOR_SKILLUP,
            ('Skill Ups - %d/%d (%.1f%%)'):fmt(ups, swings, ups / swings * 100));
    else
        imgui.TextColored(data.COLOR_SKILLUP, ('Skill Ups - %d/0'):fmt(ups));
    end
end

-- Fatigue bar
local bar_fill = nil;

local function fill_bar(fraction, color)
    local list = imgui.GetWindowDrawList();
    local w    = imgui.GetContentRegionAvail();
    local x, y = imgui.GetCursorScreenPos();
    local h    = px(data.FATIGUE_BAR_HEIGHT);
    local r    = px(data.FRAME_ROUNDING);

    list:AddRectFilled({ x, y }, { x + w, y + h },
        imgui.GetColorU32(data.COLOR_BAR_BG), r);

    if (fraction > 0) then
        list:AddRectFilled({ x, y }, { x + w * fraction, y + h },
            imgui.GetColorU32(color), r);
    end

    imgui.Dummy({ 0, h });
end

local function render_procs(charname, activity, zoneId, collected)
    local abilities = data.PROC_ABILITIES[activity];
    if (#abilities == 0) then return; end

    local line = '';
    for index, ability in ipairs(abilities) do
        if (index > 1) then line = line .. '   '; end

        local fired = store.get_proc(charname, ability.name, zoneId);

        local outof = collected;
        if (ability.basis == 'breaks') then
            outof = fired + store.get_breaks(charname, activity, zoneId);
        end

        if (outof > 0) then
            line = line .. ('%s - %d/%d (%.1f%%)')
                :fmt(ability.name, fired, outof, fired / outof * 100);
        else
            line = line .. ('%s - %d/0'):fmt(ability.name, fired);
        end
    end
    imgui.TextDisabled(line);
end

local function render_fatigue(charname, activity, zoneId, zoneName)
    local value = store.get_fatigue(charname, activity, zoneId);
    local color = get_fatigue_color(value);

    imgui.TextColored(color, ('%s: %d / %d'):fmt(zoneName, value, data.FATIGUE_CAP));

    local fraction = value / data.FATIGUE_CAP;

    if (bar_fill ~= false) then
        bar_fill = pcall(fill_bar, fraction, color);
    end

    if (not bar_fill) then
        imgui.PushStyleColor(ImGuiCol_PlotHistogram, color);
        imgui.ProgressBar(fraction, { -1, px(data.FATIGUE_BAR_HEIGHT) }, '');
        imgui.PopStyleColor(1);
    end

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

-- Tinted buttons
local function tinted_button(label, base, hover, active)
    imgui.PushStyleColor(ImGuiCol_Button,        base);
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, hover);
    imgui.PushStyleColor(ImGuiCol_ButtonActive,  active);

    local pressed = imgui.Button(label);

    imgui.PopStyleColor(3);
    return pressed;
end

-- Red: throws data away.
local function danger_button(label)
    return tinted_button(label, data.COLOR_DANGER,
        data.COLOR_DANGER_HOVER, data.COLOR_DANGER_ACTIVE);
end

-- Green: produces something.
local function success_button(label)
    return tinted_button(label, data.COLOR_SUCCESS,
        data.COLOR_SUCCESS_HOVER, data.COLOR_SUCCESS_ACTIVE);
end

local function render_item_icon(item, box, art)
    imgui.PushStyleColor(ImGuiCol_Border, item.tier.color);
    imgui.PushStyleVar(ImGuiStyleVar_ChildBorderSize, px(data.CELL_BORDER));

    CELL_PAD[1] = px(data.CELL_PADDING);
    CELL_PAD[2] = CELL_PAD[1];
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, CELL_PAD);

    BOX_SIZE[1] = box;
    BOX_SIZE[2] = box;
    ART_SIZE[1] = art;
    ART_SIZE[2] = art;

    if (imgui.BeginChild(next_cell_id(), BOX_SIZE, ImGuiChildFlags_Borders)) then
        if (item.icon ~= nil) then
            imgui.Image(item.icon.handle, ART_SIZE);
        else
            imgui.Dummy(ART_SIZE);
        end
    end
    imgui.EndChild();

    imgui.PopStyleVar(2);
    imgui.PopStyleColor(1);
end

local function render_item(item, show_icons, box, art)
    imgui.BeginGroup();

    if (show_icons) then
        local text_h = imgui.GetTextLineHeight() * 2 + px(data.ITEM_LINE_GAP);
        local top    = imgui.GetCursorPosY();

        imgui.SetCursorPosY(top + math.max(0, (text_h - box) * 0.5));
        render_item_icon(item, box, art);
        imgui.SameLine();
        imgui.SetCursorPosY(top + math.max(0, (box - text_h) * 0.5));
    end

    LINE_GAP[2] = px(data.ITEM_LINE_GAP);
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, LINE_GAP);

    imgui.BeginGroup();
    imgui.TextColored(item.tier.color, item.name);
    imgui.TextDisabled(item.label);
    imgui.EndGroup();

    imgui.PopStyleVar(1);
    imgui.EndGroup();
end

local function render_item_list(log, total)
    if (total == 0) then
        imgui.TextDisabled('  No gathers recorded yet.');
        return;
    end

    local show_icons = store.item_icons();

    local scaled = (store.icon_size() == data.SPOILS_ICON_SIZE) and font ~= nil;
    if (scaled) then
        imgui.PushFont(font, px(data.FONT_SIZE - data.SMALL_ICON_FONT_DROP));
    end

    local items  = ITEMS;
    local widest = 0;
    local count_n = 0;
    for itemName, count in pairs(log) do
        local pct  = count / total * 100;
        local name = resources.item_name(itemName);

        local label = ('%.1f%%'):fmt(pct);

        local text_width = math.max(imgui.CalcTextSize(name),
                                    imgui.CalcTextSize(label));

        if (text_width > widest) then widest = text_width; end

        count_n = count_n + 1;
        local slot = item_slot(count_n);
        slot.name   = name;
        slot.count  = count;
        slot.label  = label;
        slot.text_w = text_width;
        slot.tier   = get_rarity_tier(pct);
        slot.icon   = show_icons and icons.texture(resources.item_id(itemName)) or nil;
        items[count_n] = slot;
    end
    for index = count_n + 1, #items do items[index] = nil; end

    table.sort(items, by_count_then_name);

    local art  = px(store.icon_size());
    local box  = art + px(data.CELL_PADDING * 2 + data.CELL_BORDER * 2);
    local list = store.item_style() == 'List';

    local last_rank = nil;
    local column    = 0;
    for index, item in ipairs(items) do
        if (item.tier.rank ~= last_rank) then
            imgui.Spacing();
            imgui.Spacing();
            last_rank = item.tier.rank;
            column    = 0;
        end

        if (not list and column > 0) then
            local previous = items[index - 1];
            imgui.SameLine(0, widest - previous.text_w + px(data.CELL_GUTTER));
        end

        render_item(item, show_icons, box, art);

        if (not list) then
            column = column + 1;
            if (column >= data.ITEMS_PER_ROW) then column = 0; end
        end
    end

    if (scaled) then imgui.PopFont(); end
end

local function divider()
    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();
end

local function last_skillup_label(charname, activity, zoneId)
    local cap   = data.SKILL_CAPS[activity][zoneId];
    local skill = store.get_skill(charname, activity);

    if (cap ~= nil and skill ~= nil and skill >= cap) then
        return ('Cap (%d)'):fmt(cap);
    end
    return tostring(store.get_since_skillup(charname, activity));
end

local function render_activity(charname, activity, curZoneId, zoneName)
    local log   = store.get_item_log(charname, activity, curZoneId);
    local total = count_gathers(log);

    render_skill(charname, activity, curZoneId);
    if (not store.home_minimum()) then
        render_procs(charname, activity, curZoneId, total);
    end
    imgui.Spacing();

    render_fatigue(charname, activity, curZoneId, zoneName);

    if (store.home_minimum()) then return; end

    imgui.TextDisabled(('Items Collected - %d   Last Skill Up - %s')
        :fmt(total, last_skillup_label(charname, activity, curZoneId)));

    imgui.Spacing();
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

local function render_spoils(charname)
    local spoils     = store.get_spoils(charname);
    local show_icons = store.item_icons();

    imgui.Spacing();

    local items  = SPOILS;
    local widest = 0;
    local n      = 0;
    for itemName, count in pairs(spoils) do
        local name = resources.item_name(itemName);
        local width = imgui.CalcTextSize(name);
        if (width > widest) then widest = width; end

        n = n + 1;
        local slot = spoil_slot(n);
        slot.key    = itemName;
        slot.name   = name;
        slot.count  = count;
        slot.name_w = width;
        items[n] = slot;
    end
    for index = n + 1, #items do items[index] = nil; end

    if (n == 0) then
        imgui.TextDisabled('Nothing gathered this session.');
    else
        table.sort(items, by_name);

        SPOIL_ICON[1] = px(data.SPOILS_ICON_SIZE);
        SPOIL_ICON[2] = SPOIL_ICON[1];

        for _, item in ipairs(items) do
            if (show_icons) then
                local icon = icons.texture(resources.item_id(item.key));
                if (icon ~= nil) then
                    imgui.Image(icon.handle, SPOIL_ICON);
                else
                    imgui.Dummy(SPOIL_ICON);
                end
                imgui.SameLine();
            end

            imgui.TextDisabled(item.name);
            imgui.SameLine(0, widest - item.name_w + px(data.CELL_GUTTER));
            imgui.TextDisabled(('x%d'):fmt(item.count));
        end
    end

    divider();

    if (danger_button('Reset Spoils Session')) then
        store.reset_spoils();
    end
    imgui.TextDisabled('Clears only this tab.');
    imgui.Spacing();
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
    imgui.Spacing();

    for _, zone in ipairs(zones) do
        local log   = store.get_item_log(charname, activity, zone.id);
        local total = count_gathers(log);

        local label = zone.name;
        if (total > 0) then
            label = ('%s - %d Items Collected'):fmt(zone.name, total);
        end

        if (imgui.CollapsingHeader(('%s###hh%s%d'):fmt(label, activity, zone.id))) then
            local ups    = store.get_skillups(charname, activity, zone.id);
            local swings = store.get_attempts(charname, activity, zone.id);
            if (swings > 0) then
                imgui.TextColored(data.COLOR_SKILLUP,
                    ('Skill Ups - %d/%d (%.1f%%)'):fmt(ups, swings,
                                                       ups / swings * 100));
            end

            render_item_list(log, total);
            imgui.Spacing();
        end
    end
end

-- Activities, two per row
local function activity_pairs()
    local widest = 0;
    for _, activity in ipairs(data.ACTIVITIES) do
        local width = imgui.CalcTextSize(activity);
        if (width > widest) then widest = width; end
    end
    return widest;
end

local function render_settings(charname)
    local widest = activity_pairs();

    imgui.Spacing();

    if (imgui.Checkbox('Home Minimum Mode', { store.home_minimum() })) then
        store.toggle_home_minimum();
    end
    imgui.TextDisabled('Home shows only skill and fatigue.');

    imgui.Spacing();

    if (imgui.Checkbox('Item Icons', { store.item_icons() })) then
        store.toggle_item_icons();
    end
    imgui.TextDisabled('Show item art beside drop counts.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local sized = { store.icon_size_index() - 1 };
    if (imgui.Combo('Icon Size', sized, data.ICON_SIZE_COMBO)) then
        store.set_icon_size_index(sized[1] + 1);
    end
    imgui.PopItemWidth();
    imgui.TextDisabled('Size of the item art.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local styled = { store.item_style_index() - 1 };
    if (imgui.Combo('Item Style', styled, data.ITEM_STYLE_COMBO)) then
        store.set_item_style_index(styled[1] + 1);
    end
    imgui.PopItemWidth();
    imgui.TextDisabled('Grid packs three across, List is one per row.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local opacity = { store.window_opacity() };
    if (imgui.SliderFloat('Opacity', opacity, data.OPACITY_MIN, data.OPACITY_MAX, '%.2f')) then
        store.set_window_opacity(opacity[1]);
    end
    imgui.PopItemWidth();
    imgui.TextDisabled('Window and title bar background.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local chosen = { store.ui_scale_index() - 1 };
    if (imgui.Combo('UI Scale', chosen, data.UI_SCALE_COMBO)) then
        store.set_ui_scale_index(chosen[1] + 1);
    end
    imgui.PopItemWidth();
    imgui.TextDisabled('Size of text, icons and spacing.');

    divider();
    imgui.TextDisabled('Shown activities');
    imgui.Spacing();

    for index, activity in ipairs(data.ACTIVITIES) do
        if (imgui.Checkbox(('%s##show'):fmt(activity), { store.activity_enabled(activity) })) then
            store.toggle_activity(activity);
        end
        if (index % 2 == 1) then
            imgui.SameLine(0, widest - imgui.CalcTextSize(activity) + px(data.CELL_GUTTER));
        end
    end

    divider();
    imgui.TextDisabled('Skill levels');
    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    for index, activity in ipairs(data.ACTIVITIES) do
        local buffer = { store.get_skill(charname, activity) or 0 };
        if (imgui.InputFloat(activity, buffer, 0, 0, '%.1f')) then
            store.set_skill(charname, activity, math.max(0, buffer[1]));
            store.save();
        end
        if (index % 2 == 1) then
            imgui.SameLine(0, widest - imgui.CalcTextSize(activity) + px(data.CELL_GUTTER));
        end
    end
    imgui.PopItemWidth();

    divider();

    if (imgui.Checkbox('Auto-open on gather', { store.auto_popup() })) then
        store.toggle_auto_popup();
    end

    imgui.Spacing();

    if (imgui.Checkbox('Auto-Resize Window', { store.auto_resize() })) then
        store.toggle_auto_resize();
    end
    imgui.TextDisabled('Off: drag the gold corner to resize.');

    divider();

    if (success_button('Export CSV')) then
        actions.export();
    end
    imgui.TextDisabled('Writes a spreadsheet beside your settings.');

    imgui.Spacing();

    if (imgui.Checkbox('Minimum Data', { store.export_minimal() })) then
        store.toggle_export_minimal();
    end
    imgui.TextDisabled('Drops your name and personal counters.');

    divider();

    if (danger_button('Reset Gather/Skill Ups')) then
        actions.reset_session();
    end
    imgui.TextDisabled('Clears gather and skill up counters.');

    imgui.Spacing();

    if (danger_button('Reset All Data')) then
        actions.reset_all();
    end
    imgui.TextDisabled('Clears everything for this character.');
    imgui.Spacing();
end


local function visible_tabs()
    local n = 0;
    for _, name in ipairs(data.NAV_LEADING) do
        n = n + 1;
        TABS[n] = name;
    end
    for _, activity in ipairs(data.ACTIVITIES) do
        if (store.activity_enabled(activity)) then
            n = n + 1;
            TABS[n] = activity;
        end
    end
    for _, name in ipairs(data.NAV_TRAILING) do
        n = n + 1;
        TABS[n] = name;
    end
    for index = n + 1, #TABS do TABS[index] = nil; end
    return TABS;
end

local function render_nav(tabs)
    local showing = false;
    for _, name in ipairs(tabs) do
        if (name == ui.active_tab) then showing = true; break; end
    end
    if (not showing) then ui.active_tab = tabs[1]; end

    for index, name in ipairs(tabs) do
        if (index > 1) then imgui.SameLine(0, px(data.NAV_GAP)); end

        local selected = (name == ui.active_tab);
        if (selected) then
            imgui.PushStyleColor(ImGuiCol_Button, data.COLOR_NAV_SELECTED);
        end

        if (imgui.Button(nav_label(name))) then
            ui.active_tab = name;
        end

        if (selected) then imgui.PopStyleColor(1); end
    end
end

function ui.render(charname, curZoneId)
    resources.scan_chunk();

    if (not ui.visible) then return; end

    window_style();
    cell_id      = 0;
    scale        = store.ui_scale();
    WINDOW_BG[4] = store.window_opacity();

    for _, entry in ipairs(STYLE_COLORS) do
        imgui.PushStyleColor(entry[1], entry[2]);
    end
    for _, entry in ipairs(STYLE_VARS) do
        imgui.PushStyleVar(entry[1], entry[2]);
    end

    if (font ~= nil) then imgui.PushFont(font, px(data.FONT_SIZE)); end

    imgui.SetNextWindowSize(FIRST_SIZE, ImGuiCond_FirstUseEver);

    local flags = ImGuiWindowFlags_None;
    if (store.auto_resize()) then flags = ImGuiWindowFlags_AlwaysAutoResize; end

    IS_OPEN[1] = ui.visible;
    if (imgui.Begin(title, IS_OPEN, flags)) then
        imgui.Text(('Character: %s'):fmt(charname));
        imgui.Separator();

        render_nav(visible_tabs());
        imgui.Spacing();

        local active = ui.active_tab;
        if (active == 'Home') then
            render_home(charname, curZoneId);
        elseif (active == 'Spoils') then
            render_spoils(charname);
        elseif (active == 'Settings') then
            render_settings(charname);
        else
            render_activity_tab(charname, active);
        end
    end
    imgui.End();

    if (font ~= nil) then imgui.PopFont(); end

    imgui.PopStyleVar(#STYLE_VARS);
    imgui.PopStyleColor(#STYLE_COLORS);

    ui.visible = IS_OPEN[1];
end

return ui;

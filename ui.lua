require('common');

local imgui     = require('imgui');
local data      = require('data');
local store     = require('store');
local resources = require('resources');
local icons     = require('icons');

local ui = T{};

-- Window state, neither persisted. The window starts closed, and it opens on
-- Home every session because that is where a player wants to start.
ui.visible    = false;
ui.active_tab = 'Home';

local actions = T{};

local WINDOW_BG = { 0, 0, 0, 1 };

-- Set once per frame from the stored setting. Every pixel measurement in this
-- file goes through px() so one setting moves all of them together; a constant
-- used raw would stay put while everything around it grew.
local scale = 1.0;

local function px(value)
    return value * scale;
end

-- Every bordered icon box is an ImGui child, and child ids must be unique
-- within a window. Numbering them by their position in one zone's item list
-- reuses '##hhitem1' for every open foldout on an activity tab, and ImGui
-- then refuses to draw the duplicates: the first zone renders and the rest
-- lose their icons and their alignment. Counted across the whole frame
-- instead, and reset at the top of ui.render.
local cell_id = 0;

local function next_cell_id()
    cell_id = cell_id + 1;
    return ('##hhitem%d'):fmt(cell_id);
end

-- Built on first render rather than at load, because Ashita defines the
-- ImGuiCol_ globals when imgui is required and data.lua is required first.
-- WINDOW_BG appears by reference, so updating its alpha updates it here too.
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
    imgui.ProgressBar(value / data.FATIGUE_CAP, { -1, px(14) }, '');
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

-- All three states are pushed, or the button reverts to charcoal on hover,
-- which is when its colour matters most. Defined up here because Spoils
-- uses a tinted button well before Settings does.
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

-- The border is the rarity marker, so it is drawn at whichever icon size is
-- selected rather than only at the large one.
local function render_item_icon(item, box, art)
    imgui.PushStyleColor(ImGuiCol_Border, item.tier.color);
    imgui.PushStyleVar(ImGuiStyleVar_ChildBorderSize, px(data.CELL_BORDER));
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding,
        { px(data.CELL_PADDING), px(data.CELL_PADDING) });

    if (imgui.BeginChild(next_cell_id(), { box, box },
                         ImGuiChildFlags_Borders)) then
        if (item.icon ~= nil) then
            imgui.Image(item.icon.handle, { art, art });
        else
            imgui.Dummy({ art, art });
        end
    end
    imgui.EndChild();

    imgui.PopStyleVar(2);
    imgui.PopStyleColor(1);
end

-- Grid: name above its percentage, three across.
local function render_item(item, show_icons, box, art)
    imgui.BeginGroup();

    if (show_icons) then
        render_item_icon(item, box, art);
        imgui.SameLine();
    end

    imgui.BeginGroup();
    imgui.TextColored(item.tier.color, item.name);
    imgui.TextDisabled(item.label);
    imgui.EndGroup();

    imgui.EndGroup();
end

-- List: one item per row, percentages aligned in a column.
local function render_item_row(item, show_icons, box, art, widest)
    imgui.BeginGroup();

    if (show_icons) then
        render_item_icon(item, box, art);
        imgui.SameLine();
    end

    imgui.TextColored(item.tier.color, item.name);
    imgui.SameLine(0, widest - item.name_w + px(data.CELL_GUTTER));
    imgui.TextDisabled(item.label);

    imgui.EndGroup();
end

local function render_item_list(log, total)
    if (total == 0) then
        imgui.TextDisabled('  No gathers recorded yet.');
        return;
    end

    local show_icons = store.item_icons();

    local items  = T{};
    local widest = 0;
    for itemName, count in pairs(log) do
        local pct  = count / total * 100;
        local name = resources.item_name(itemName);

        -- Built here rather than at draw time because its width sets the
        -- column, so the measured string and the drawn string must be one.
        local label = ('%.1f%%'):fmt(pct);

        -- The name and the label are stacked, so the wider of the two decides
        -- the column. A short name with a long label would otherwise overhang
        -- its column and push the next one out of line.
        local name_width = imgui.CalcTextSize(name);
        local text_width = math.max(name_width, imgui.CalcTextSize(label));

        if (text_width > widest) then widest = text_width; end

        table.insert(items, {
            name   = name,
            count  = count,
            label  = label,
            name_w = name_width,
            text_w = text_width,
            tier   = get_rarity_tier(pct),
            icon   = show_icons and icons.texture(resources.item_id(itemName)) or nil,
        });
    end

    table.sort(items, function(a, b)
        if (a.count ~= b.count) then
            return a.count > b.count;
        end
        return a.name < b.name;
    end);

    local art  = px(store.icon_size());
    local box  = art + px(data.CELL_PADDING * 2 + data.CELL_BORDER * 2);
    local list = store.item_style() == 'List';

    local last_rank = nil;
    local column    = 0;
    for index, item in ipairs(items) do
        -- No tier heading: the rarity is carried by the item name's colour and
        -- its border. The blank line and the row break are what keep the
        -- tiers reading as separate blocks, so both must stay.
        if (item.tier.rank ~= last_rank) then
            imgui.Spacing();
            imgui.Spacing();
            last_rank = item.tier.rank;
            column    = 0;
        end

        if (list) then
            render_item_row(item, show_icons, box, art, widest);
        else
            -- Padding the gap by however much narrower the previous item's
            -- text was keeps every column starting at the same x, without
            -- needing to box the text in a fixed-width child.
            if (column > 0) then
                local previous = items[index - 1];
                imgui.SameLine(0, widest - previous.text_w + px(data.CELL_GUTTER));
            end

            render_item(item, show_icons, box, art);

            column = column + 1;
            if (column >= data.ITEMS_PER_ROW) then column = 0; end
        end
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
        imgui.TextDisabled(('Gathers - %d/%d (%.1f%%)   Skill Ups - %d/%d (%.1f%%)')
            :fmt(successes, attempts, successes / attempts * 100,
                 skillups, attempts, skillups / attempts * 100));
    else
        imgui.TextDisabled(('Gathers 0/0   Skill Ups %d/0'):fmt(skillups));
    end

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

    local items  = T{};
    local widest = 0;
    for itemName, count in pairs(spoils) do
        local name = resources.item_name(itemName);
        local width = imgui.CalcTextSize(name);
        if (width > widest) then widest = width; end

        table.insert(items, {
            key    = itemName,
            name   = name,
            count  = count,
            name_w = width,
        });
    end

    if (#items == 0) then
        imgui.TextDisabled('Nothing gathered this session.');
    else
        table.sort(items, function(a, b) return a.name < b.name; end);

        for _, item in ipairs(items) do
            if (show_icons) then
                local icon = icons.texture(resources.item_id(item.key));
                if (icon ~= nil) then
                    imgui.Image(icon.handle,
                        { px(data.SPOILS_ICON_SIZE), px(data.SPOILS_ICON_SIZE) });
                else
                    imgui.Dummy({ px(data.SPOILS_ICON_SIZE), px(data.SPOILS_ICON_SIZE) });
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

-- Activities are laid out two per row. The pad is measured rather than fixed
-- so the right-hand column starts at the same x on both rows whatever the
-- label lengths and whatever the UI Scale.
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
    -- Combo indexes from zero; store keeps a Lua 1-based index. Converting at
    -- this boundary is the whole of it, and getting it wrong is quiet: the
    -- menu shows the wrong row and picking the first entry writes nil.
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

    if (danger_button('Reset Gather/Skill Ups')) then
        actions.reset_session();
    end
    imgui.TextDisabled('Clears gather and skill up counters.');

    imgui.Spacing();

    if (danger_button('Reset All Data')) then
        actions.reset_all();
    end
    imgui.TextDisabled('Clears everything for this character.');

    divider();

    if (success_button('Export CSV')) then
        actions.export();
    end
    imgui.TextDisabled('Writes a spreadsheet beside your settings.');
    imgui.Spacing();
end


local function visible_tabs()
    local tabs = T{};
    for _, name in ipairs(data.NAV_LEADING) do
        table.insert(tabs, name);
    end
    for _, activity in ipairs(data.ACTIVITIES) do
        if (store.activity_enabled(activity)) then
            table.insert(tabs, activity);
        end
    end
    for _, name in ipairs(data.NAV_TRAILING) do
        table.insert(tabs, name);
    end
    return tabs;
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

        -- The ##nav suffix is hidden from the label but keeps each id unique
        -- against the reset buttons, which can share a panel with these.
        if (imgui.Button(('%s##nav'):fmt(name))) then
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

    imgui.SetNextWindowSize({ 360, 0, }, ImGuiCond_FirstUseEver);

    local flags = ImGuiWindowFlags_None;
    if (store.auto_resize()) then flags = ImGuiWindowFlags_AlwaysAutoResize; end

    local isOpen = { ui.visible };
    if (imgui.Begin(title, isOpen, flags)) then
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

    ui.visible = isOpen[1];
end

return ui;

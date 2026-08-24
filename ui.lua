require('common');

local imgui     = require('imgui');
local data      = require('data');
local store     = require('store');
local resources = require('resources');
local icons     = require('icons');

local ui = T{};

ui.visible    = false;
ui.active_tab = 'Home';
ui.editing_prices = false;
ui.armed = nil;
ui.armed_at = 0;

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

local function pooled(pool, index)
    local slot = pool[index];
    if (slot == nil) then
        slot = {};
        pool[index] = slot;
    end
    return slot;
end

local function by_count_then_name(a, b)
    if (a.tier.rank ~= b.tier.rank) then return a.tier.rank < b.tier.rank; end
    if (a.count ~= b.count) then return a.count > b.count; end
    return a.name < b.name;
end

local PRICE_ROWS  = {};
local PRICE_SLOTS = {};

local function by_activity_then_name(a, b)
    if (a.order ~= b.order) then return a.order < b.order; end
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

local FIRST_SIZE = { 360, 0 };
local IS_OPEN    = { false };
local TABS       = T{};
local SPOIL_ICON = { 0, 0 };
local BOX_SIZE   = { 0, 0 };
local ART_SIZE   = { 0, 0 };
local LINE_GAP   = { 0, 0 };
local PRICE_BOX  = { 0, 0 };

local STYLE_COLORS;
local STYLE_VARS;

local function window_style()
    if (STYLE_COLORS ~= nil) then return; end

    STYLE_COLORS = T{
        { ImGuiCol_WindowBg,         WINDOW_BG },
        { ImGuiCol_TitleBg,          WINDOW_BG },
        { ImGuiCol_TitleBgActive,    WINDOW_BG },
        { ImGuiCol_TitleBgCollapsed, WINDOW_BG },
        { ImGuiCol_TextDisabled,     data.COLOR_LABEL },

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

local function get_fatigue_color(value, cap)
    if (value >= cap) then
        return data.COLOR_HIGH;
    elseif (value >= cap * data.FATIGUE_WARN_RATIO) then
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

local CLIP_MIN = { 0, 0 };
local CLIP_MAX = { 0, 0 };
local TEXT_POS = { 0, 0 };

local function clip_text(list, x0, x1, y0, y1, col, text)
    CLIP_MIN[1] = x0;
    CLIP_MIN[2] = y0;
    CLIP_MAX[1] = x1;
    CLIP_MAX[2] = y1;

    list:PushClipRect(CLIP_MIN, CLIP_MAX, true);
    local ok, err = pcall(list.AddText, list, TEXT_POS, col, text);
    list:PopClipRect();

    if (not ok) then error(err, 0); end
end

local right_fill = nil;
local RIGHT_POS  = { 0, 0 };

local function right_text(text, color, right, top)
    RIGHT_POS[1] = right - imgui.CalcTextSize(text);
    RIGHT_POS[2] = top;
    imgui.GetWindowDrawList():AddText(RIGHT_POS,
        imgui.GetColorU32(color), text);
end

local TILE_SIZE = { 0, 0 };
local TILE_PAD  = { 0, 0 };
local TILE_LINE = { 0, 0 };
local TILES     = {};

local function tile(index, label, value, color)
    local slot = TILES[index];
    if (slot == nil) then slot = {}; TILES[index] = slot; end
    slot.label, slot.value, slot.color = label, value, color;
    return slot;
end

local TILE_MIN  = { 0, 0 };
local TILE_MAX  = { 0, 0 };
local tile_fill = nil;

local function paint_tiles(count, x, y, w, h)
    local list  = imgui.GetWindowDrawList();
    local gap   = px(data.TILE_GAP);
    local width = (w - gap * (count - 1)) / count;
    local padx  = px(data.TILE_PAD_X);
    local pady  = px(data.TILE_PAD_Y);
    local drop  = imgui.GetTextLineHeight() + px(data.ITEM_LINE_GAP);
    local plate = imgui.GetColorU32(data.COLOR_TILE_BG);
    local cap   = imgui.GetColorU32(data.COLOR_CAPTION);

    for index = 1, count do
        local slot = TILES[index];
        local left = x + (width + gap) * (index - 1);

        TILE_MIN[1] = left;
        TILE_MIN[2] = y;
        TILE_MAX[1] = left + width;
        TILE_MAX[2] = y + h;
        list:AddRectFilled(TILE_MIN, TILE_MAX, plate, px(data.FRAME_ROUNDING));

        TEXT_POS[1] = left + padx;
        TEXT_POS[2] = y + pady;
        clip_text(list, left, left + width, y, y + h, cap, slot.label);

        TEXT_POS[2] = y + pady + drop;
        clip_text(list, left, left + width, y, y + h,
            imgui.GetColorU32(slot.color or data.COLOR_VALUE), slot.value);
    end
end

local function lay_out_tiles(count, avail, height)
    local gap = px(data.TILE_GAP);

    TILE_PAD[1] = px(data.TILE_PAD_X);
    TILE_PAD[2] = px(data.TILE_PAD_Y);
    TILE_LINE[1] = 0;
    TILE_LINE[2] = px(data.ITEM_LINE_GAP);

    TILE_SIZE[1] = (avail - gap * (count - 1)) / count;
    TILE_SIZE[2] = height;

    imgui.PushStyleColor(ImGuiCol_ChildBg, data.COLOR_TILE_BG);
    imgui.PushStyleVar(ImGuiStyleVar_ChildRounding, px(data.FRAME_ROUNDING));
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, TILE_PAD);
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, TILE_LINE);

    for index = 1, count do
        if (index > 1) then imgui.SameLine(0, gap); end
        local slot = TILES[index];
        imgui.BeginChild(('##hhtile%d'):fmt(index), TILE_SIZE,
            ImGuiChildFlags_AlwaysUseWindowPadding, ImGuiWindowFlags_NoScrollbar);
        imgui.TextColored(data.COLOR_CAPTION, slot.label);
        imgui.TextColored(slot.color or data.COLOR_VALUE, slot.value);
        imgui.EndChild();
    end

    imgui.PopStyleVar(3);
    imgui.PopStyleColor(1);
end

local function render_tiles(count)
    local avail  = imgui.GetContentRegionAvail();
    local height = imgui.GetTextLineHeight() * 2 + px(data.ITEM_LINE_GAP)
                   + px(data.TILE_PAD_Y) * 2;

    if (tile_fill ~= false) then
        local x, y = imgui.GetCursorScreenPos();
        tile_fill = pcall(paint_tiles, count, x, y, avail, height);
    end

    if (not tile_fill) then
        lay_out_tiles(count, avail, height);
        return;
    end

    TILE_SIZE[1] = 0;
    TILE_SIZE[2] = height;
    imgui.Dummy(TILE_SIZE);
end



local function render_skill_head(charname, activity)
    local head  = activity:upper();
    local skill = store.get_skill(charname, activity);
    local text  = skill == nil and 'unknown' or ('%.1f'):fmt(skill);

    local avail = imgui.GetContentRegionAvail();
    local x, y  = imgui.GetCursorScreenPos();

    imgui.TextColored(data.COLOR_CAPTION, head);

    if (right_fill ~= false) then
        right_fill = pcall(right_text, text, data.COLOR_VALUE, x + avail, y);
    end

    if (not right_fill) then
        local hw = imgui.CalcTextSize(head);
        local vw = imgui.CalcTextSize(text);
        imgui.SameLine(0, math.max(0, avail - hw - vw));
        imgui.TextColored(data.COLOR_VALUE, text);
    end
end

local function as_rate(part, whole)
    if (whole <= 0) then return '-'; end
    return ('%.1f%%'):fmt(part / whole * 100);
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

local BAR_MIN  = { 0, 0 };
local BAR_MAX  = { 0, 0 };
local BAR_SIZE = { 0, 0 };

local function fill_bar(fraction, color)
    local list = imgui.GetWindowDrawList();
    local w    = imgui.GetContentRegionAvail();
    local x, y = imgui.GetCursorScreenPos();
    local h    = px(data.FATIGUE_BAR_HEIGHT);
    local r    = h * 0.5;

    BAR_MIN[1] = x;
    BAR_MIN[2] = y;
    BAR_MAX[1] = x + w;
    BAR_MAX[2] = y + h;
    list:AddRectFilled(BAR_MIN, BAR_MAX, imgui.GetColorU32(data.COLOR_BAR_BG), r);

    if (fraction > 0) then
        BAR_MAX[1] = x + w * fraction;
        list:AddRectFilled(BAR_MIN, BAR_MAX, imgui.GetColorU32(color), r);
    end

    BAR_SIZE[1] = 0;
    BAR_SIZE[2] = h;
    imgui.Dummy(BAR_SIZE);
end

-- Hover help.
local function hint(text)
    if (imgui.IsItemHovered()) then imgui.SetTooltip(text); end
end

local PROC_PARTS = {};
local REPEAT_NAMES = {};

local function repeat_note(charname, zoneId)
    local names, count = REPEAT_NAMES, 0;

    for itemName, tally in pairs(store.get_repeats(charname, zoneId)) do
        count = count + 1;
        names[count] = ('%s x%d'):fmt(resources.item_name(itemName), tally);
    end
    for index = count + 1, #names do names[index] = nil; end

    if (count == 0) then
        return 'Nothing has dropped from a Gold Rush node here yet.';
    end

    table.sort(names);
    return ('From Gold Rush nodes here:\n%s\n\n%s'):fmt(
        table.concat(names, '\n', 1, count),
        store.count_repeats()
            and 'These are counted in the rates above.'
            or  'These are left out of the rates above.');
end

local function render_procs(charname, activity, zoneId, collected, quiet)
    local abilities = data.PROC_ABILITIES[activity];
    if (#abilities == 0) then return; end

    local shown = false;

    for index, ability in ipairs(abilities) do
        local fired = store.get_proc(charname, ability.name, zoneId);

        local outof = collected;
        if (ability.basis == 'breaks') then
            outof = fired + store.get_breaks(charname, activity, zoneId);
        end

        if (fired > 0 or outof > 0) then shown = true; end

        local slot = PROC_PARTS[index];
        if (slot == nil) then slot = {}; PROC_PARTS[index] = slot; end
        slot.repeats = ability.repeats;

        if (outof > 0) then
            slot.text = ('%s - %d/%d (%.1f%%)')
                :fmt(ability.name, fired, outof, fired / outof * 100);
        else
            slot.text = ('%s - %d/0'):fmt(ability.name, fired);
        end
    end

    if (quiet and not shown) then return; end

    for index = 1, #abilities do
        if (index > 1) then imgui.SameLine(0, px(data.PROC_GAP)); end

        local slot = PROC_PARTS[index];
        imgui.TextDisabled(slot.text);
        if (slot.repeats) then hint(repeat_note(charname, zoneId)); end
    end
end

local function render_fatigue(charname, activity, zoneId, zoneName)
    local value = store.get_fatigue(charname, activity, zoneId);
    local cap   = store.fatigue_cap(charname, activity, zoneId);
    local color = get_fatigue_color(value, cap);
    local count = ('%d / %d'):fmt(value, cap);

    local fraction = value / cap;

    local avail = imgui.GetContentRegionAvail();
    local x, y  = imgui.GetCursorScreenPos();

    imgui.TextColored(data.COLOR_VALUE, zoneName);

    if (right_fill ~= false) then
        right_fill = pcall(right_text, count, data.COLOR_LABEL, x + avail, y);
    end

    if (not right_fill) then
        local zw = imgui.CalcTextSize(zoneName);
        local cw = imgui.CalcTextSize(count);
        imgui.SameLine(0, math.max(0, avail - zw - cw));
        imgui.TextColored(data.COLOR_LABEL, count);
    end

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


-- Red: throws data away. Takes two clicks.
local DANGER_SIZE = { 0, 0 };

local function danger_button(label)
    local now   = os.clock();
    local armed = (ui.armed == label)
                  and (now - ui.armed_at) < data.CONFIRM_SECONDS;

    if (ui.armed == label and not armed) then ui.armed = nil; end

    local wide = imgui.CalcTextSize(label);
    local ask  = imgui.CalcTextSize(data.CONFIRM_LABEL);
    DANGER_SIZE[1] = math.max(wide, ask) + px(data.BUTTON_PAD) * 2;
    DANGER_SIZE[2] = imgui.GetFrameHeight();

    imgui.PushStyleColor(ImGuiCol_Button,
        armed and data.COLOR_DANGER_ACTIVE or data.COLOR_DANGER);
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, data.COLOR_DANGER_HOVER);
    imgui.PushStyleColor(ImGuiCol_ButtonActive,  data.COLOR_DANGER_ACTIVE);

    local pressed = imgui.Button(('%s###%s')
        :fmt(armed and data.CONFIRM_LABEL or label, label), DANGER_SIZE);

    imgui.PopStyleColor(3);

    if (not pressed) then return false; end

    if (armed) then
        ui.armed = nil;
        return true;
    end

    ui.armed    = label;
    ui.armed_at = now;
    return false;
end

-- Green: produces something.
local function success_button(label)
    return tinted_button(label, data.COLOR_SUCCESS,
        data.COLOR_SUCCESS_HOVER, data.COLOR_SUCCESS_ACTIVE);
end

local function render_item_icon(item, art)
    BOX_SIZE[1] = art;
    BOX_SIZE[2] = art;
    ART_SIZE[1] = art;
    ART_SIZE[2] = art;

    if (imgui.BeginChild(next_cell_id(), BOX_SIZE,
                         ImGuiChildFlags_None, ImGuiWindowFlags_NoScrollbar)) then
        if (item.icon ~= nil) then
            imgui.Image(item.icon.handle, ART_SIZE);
        else
            imgui.Dummy(ART_SIZE);
        end
    end
    imgui.EndChild();
end

local function render_item(item, show_icons, art)
    imgui.BeginGroup();

    if (show_icons) then
        local text_h = imgui.GetTextLineHeight() * 2 + px(data.ITEM_LINE_GAP);
        local top    = imgui.GetCursorPosY();

        imgui.SetCursorPosY(top + math.max(0, (text_h - art) * 0.5));
        render_item_icon(item, art);
        imgui.SameLine();
        imgui.SetCursorPosY(top + math.max(0, (art - text_h) * 0.5));
    end

    LINE_GAP[2] = px(data.ITEM_LINE_GAP);
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, LINE_GAP);

    imgui.BeginGroup();
    imgui.TextColored(item.tier.color, item.name);
    if (item.muted) then
        imgui.TextColored(item.tier.color, item.label);
    else
        imgui.TextDisabled(item.label);
    end
    imgui.EndGroup();

    imgui.PopStyleVar(1);
    imgui.EndGroup();
end

local SEEN = {};

local function render_item_list(log, total, charname, activity, zoneId)
    local known = store.zone_items(activity, zoneId);

    if (total == 0 and #known == 0) then
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

    local seen = SEEN;
    for key in pairs(seen) do seen[key] = nil; end

    for itemName, count in pairs(log) do
        local pct  = total > 0 and (count / total * 100) or 0;
        local name = resources.item_name(itemName);
        seen[name] = true;

        local label = ('%.1f%%'):fmt(pct);

        local text_width = math.max(imgui.CalcTextSize(name),
                                    imgui.CalcTextSize(label));

        if (text_width > widest) then widest = text_width; end

        count_n = count_n + 1;
        local slot = pooled(SLOTS, count_n);
        slot.name   = name;
        slot.count  = count;
        slot.label  = label;
        slot.text_w = text_width;
        slot.tier   = get_rarity_tier(pct);
        slot.muted  = false;
        slot.icon   = show_icons and icons.texture(resources.item_id(itemName)) or nil;
        items[count_n] = slot;
    end

    for _, entry in ipairs(known) do
        local shown = resources.item_name(entry.name);
        if (not seen[shown]) then
            local locked = store.item_locked(charname, activity, zoneId, entry.name);
            local label  = locked and ('Locked (%d)'):fmt(locked) or 'Not seen';

            local text_width = math.max(imgui.CalcTextSize(shown),
                                        imgui.CalcTextSize(label));
            if (text_width > widest) then widest = text_width; end

            count_n = count_n + 1;
            local slot = pooled(SLOTS, count_n);
            slot.name   = shown;
            slot.count  = 0;
            slot.label  = label;
            slot.text_w = text_width;
            slot.tier   = locked and data.TIER_LOCKED or data.TIER_UNSEEN;
            slot.muted  = true;
            slot.icon   = show_icons and icons.texture(resources.item_id(entry.name)) or nil;
            items[count_n] = slot;
        end
    end
    for index = count_n + 1, #items do items[index] = nil; end

    table.sort(items, by_count_then_name);

    local art  = px(store.icon_size());
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

        render_item(item, show_icons, art);

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

    render_skill_head(charname, activity);
    imgui.Spacing();

    render_fatigue(charname, activity, curZoneId, zoneName);

    if (store.home_minimum()) then return; end

    local ups    = store.get_skillups(charname, activity, curZoneId);
    local swings = store.get_attempts(charname, activity, curZoneId);

    tile(1, 'COLLECTED', ('%d'):fmt(total));
    tile(2, 'SKILL UPS', as_rate(ups, swings), data.COLOR_SKILLUP);
    tile(3, 'LAST SKILL', last_skillup_label(charname, activity, curZoneId));
    render_tiles(3);

    imgui.Spacing();
    render_procs(charname, activity, curZoneId, total);

    imgui.Spacing();
    render_item_list(log, total, charname, activity, curZoneId);
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

local function span_label(seconds)
    local hours = math.floor(seconds / data.SECONDS_PER_HOUR);
    local mins  = math.floor(seconds % data.SECONDS_PER_HOUR / 60);
    if (hours > 0) then return ('%dh %dm'):fmt(hours, mins); end
    if (mins > 0) then return ('%dm'):fmt(mins); end
    return ('%ds'):fmt(seconds);
end

local function gil(value)
    local text = tostring(math.floor(value));
    local head = #text % 3;
    if (head == 0) then head = 3; end

    local out = text:sub(1, head);
    for index = head + 1, #text, 3 do
        out = out .. ',' .. text:sub(index, index + 2);
    end
    return out;
end

local PRICE_BUFFER = {};

local function render_price_editor()
    imgui.TextDisabled('Set what each item sells for. Spoils multiplies it by your count.');
    imgui.Spacing();

    PRICE_BOX[1] = 0;
    PRICE_BOX[2] = px(data.PRICE_EDITOR_HEIGHT);
    imgui.BeginChild('##hhprices', PRICE_BOX, ImGuiChildFlags_Borders);

    local show_icons = store.item_icons();
    SPOIL_ICON[1] = px(data.SPOILS_ICON_SIZE);
    SPOIL_ICON[2] = SPOIL_ICON[1];

    local rows   = PRICE_ROWS;
    local widest = 0;
    local n      = 0;
    for order, activity in ipairs(data.ACTIVITIES) do
        for _, key in ipairs(store.priced_items(activity)) do
            local name  = resources.item_name(key);
            local width = imgui.CalcTextSize(name);
            if (width > widest) then widest = width; end

            n = n + 1;
            local slot = pooled(PRICE_SLOTS, n);
            slot.key      = key;
            slot.name     = name;
            slot.name_w   = width;
            slot.activity = activity;
            slot.order    = order;
            rows[n] = slot;
        end
    end
    for index = n + 1, #rows do rows[index] = nil; end

    table.sort(rows, by_activity_then_name);

    local shown = nil;
    imgui.PushItemWidth(px(data.PRICE_INPUT_WIDTH));
    for _, item in ipairs(rows) do
        if (item.activity ~= shown) then
            if (shown ~= nil) then imgui.Spacing(); end
            shown = item.activity;
            imgui.TextColored(data.COLOR_SKILLUP, item.activity);
            imgui.Spacing();
        end

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

        if (resources.price_key(item.key) == nil) then
            imgui.TextColored(data.COLOR_HIGH, '(?)');
        else
            PRICE_BUFFER[1] = store.get_price(item.activity, item.key);
            if (imgui.InputInt(('##hhprice%s%s'):fmt(item.activity, item.key),
                               PRICE_BUFFER, 0, 0)) then
                store.set_price(item.activity, item.key, PRICE_BUFFER[1]);
            end
        end
    end
    imgui.PopItemWidth();

    imgui.EndChild();
    imgui.Spacing();

    if (imgui.Button('Done')) then
        ui.editing_prices = false;
    end
    imgui.SameLine(0, px(data.NAV_GAP));
    hint('Saved as you type.');
    imgui.Spacing();
end

local function render_spoils(charname)
    if (ui.editing_prices) then
        render_price_editor();
        return;
    end

    local spoils     = store.get_spoils(charname);
    local show_icons = store.item_icons();

    imgui.Spacing();

    local items   = SPOILS;
    local widest  = 0;
    local widestc = 0;
    local n       = 0;
    for itemName, count in pairs(spoils) do
        local name = resources.item_name(itemName);
        local width = imgui.CalcTextSize(name);
        if (width > widest) then widest = width; end

        n = n + 1;
        local slot = pooled(SPOIL_SLOTS, n);
        slot.key    = itemName;
        slot.name   = name;
        slot.count  = count;
        slot.name_w = width;
        slot.profit = count * store.price_of(itemName);
        slot.tally  = ('x%d'):fmt(count);
        slot.tally_w = imgui.CalcTextSize(slot.tally);
        if (slot.tally_w > widestc) then widestc = slot.tally_w; end
        items[n] = slot;
    end
    for index = n + 1, #items do items[index] = nil; end

    if (n == 0) then
        imgui.TextDisabled('Nothing gathered this session.');
    else
        table.sort(items, by_name);

        SPOIL_ICON[1] = px(data.SPOILS_ICON_SIZE);
        SPOIL_ICON[2] = SPOIL_ICON[1];

        local head  = data.SPOILS_HEADERS;
        local head1 = imgui.CalcTextSize(head[1]);
        local head2 = imgui.CalcTextSize(head[2]);
        if (head1 > widest)  then widest  = head1; end
        if (head2 > widestc) then widestc = head2; end

        if (show_icons) then
            imgui.Dummy(SPOIL_ICON);
            imgui.SameLine();
        end
        imgui.Text(head[1]);
        imgui.SameLine(0, widest - head1 + px(data.CELL_GUTTER));
        imgui.Text(head[2]);
        imgui.SameLine(0, widestc - head2 + px(data.CELL_GUTTER));
        imgui.Text(head[3]);
        imgui.Spacing();

        local total = 0;
        for _, item in ipairs(items) do
            total = total + item.profit;

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
            imgui.TextDisabled(item.tally);
            imgui.SameLine(0, widestc - item.tally_w + px(data.CELL_GUTTER));
            imgui.TextColored(data.COLOR_SKILLUP, gil(item.profit));
        end

        imgui.Spacing();
        imgui.TextColored(data.COLOR_SKILLUP, ('Total - %s Gil'):fmt(gil(total)));

        local span = store.session_span(charname);
        if (span > 0) then
            imgui.TextColored(data.COLOR_GOLD, ('Per Hour - %s Gil   over %s')
                :fmt(gil(total * data.SECONDS_PER_HOUR / span), span_label(span)));
        else
            imgui.TextColored(data.COLOR_GOLD, 'Per Hour - not enough time yet');
        end
    end

    divider();

    if (imgui.Button('Edit Prices')) then
        ui.editing_prices = true;
    end
    imgui.SameLine(0, px(data.NAV_GAP));
    if (danger_button('Reset Spoils Session')) then
        store.reset_spoils();
    end
    hint('Clears only this tab.');
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

            render_procs(charname, activity, zone.id, total, true);

            render_item_list(log, total, charname, activity, zone.id);
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
    hint('Home shows only skill and fatigue.');

    imgui.Spacing();

    if (imgui.Checkbox('Item Icons', { store.item_icons() })) then
        store.toggle_item_icons();
    end
    hint('Show item art beside drop counts.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local sized = { store.icon_size_index() - 1 };
    if (imgui.Combo('Item Size', sized, data.ICON_SIZE_COMBO)) then
        store.set_icon_size_index(sized[1] + 1);
    end
    imgui.PopItemWidth();
    hint('Size of the item art and its text.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local styled = { store.item_style_index() - 1 };
    if (imgui.Combo('Item Style', styled, data.ITEM_STYLE_COMBO)) then
        store.set_item_style_index(styled[1] + 1);
    end
    imgui.PopItemWidth();
    hint('Grid packs three across, List is one per row.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local opacity = { store.window_opacity() };
    if (imgui.SliderFloat('Opacity', opacity, data.OPACITY_MIN, data.OPACITY_MAX, '%.2f')) then
        store.set_window_opacity(opacity[1]);
    end
    imgui.PopItemWidth();
    hint('Window and title bar background.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    local chosen = { store.ui_scale_index() - 1 };
    if (imgui.Combo('UI Scale', chosen, data.UI_SCALE_COMBO)) then
        store.set_ui_scale_index(chosen[1] + 1);
    end
    imgui.PopItemWidth();
    hint('Size of text, icons and spacing.');

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

    if (imgui.Checkbox('Count Gold Rush Drops', { store.count_repeats() })) then
        store.toggle_count_repeats();
    end
    hint('Gold Rush makes a node repeat one item. Off keeps those repeats out '
         .. 'of your drop rates.');

    imgui.Spacing();

    if (imgui.Checkbox('Auto-open on gather', { store.auto_popup() })) then
        store.toggle_auto_popup();
    end

    imgui.Spacing();

    if (imgui.Checkbox('Auto-Resize Window', { store.auto_resize() })) then
        store.toggle_auto_resize();
    end
    hint('Off: drag the gold corner to resize.');

    divider();

    if (success_button('Export CSV')) then
        actions.export();
    end
    hint('Writes a spreadsheet beside your settings.');

    imgui.Spacing();

    if (imgui.Checkbox('Minimum Data', { store.export_minimal() })) then
        store.toggle_export_minimal();
    end
    hint('Drops your name and personal counters.');

    divider();

    if (danger_button('Reset Gather/Skill Ups')) then
        actions.reset_session();
    end
    hint('Clears gather and skill up counters.');

    imgui.Spacing();

    if (danger_button('Reset All Data')) then
        actions.reset_all();
    end
    hint('Clears everything for this character.');
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

local NAV_MIN  = { 0, 0 };
local NAV_MAX  = { 0, 0 };
local nav_fill = nil;

local function nav_track(x, y, w, h)
    NAV_MIN[1] = x;
    NAV_MIN[2] = y;
    NAV_MAX[1] = x + w;
    NAV_MAX[2] = y + h;

    imgui.GetWindowDrawList():AddRectFilled(NAV_MIN, NAV_MAX,
        imgui.GetColorU32(data.COLOR_NAV_TRACK), px(data.FRAME_ROUNDING));
end

local function render_nav(tabs)
    local showing = false;
    for _, name in ipairs(tabs) do
        if (name == ui.active_tab) then showing = true; break; end
    end
    if (not showing) then ui.active_tab = tabs[1]; end

    if (nav_fill ~= false) then
        local x, y = imgui.GetCursorScreenPos();
        nav_fill = pcall(nav_track, x, y, imgui.GetContentRegionAvail(),
                                          imgui.GetFrameHeight());
    end

    for index, name in ipairs(tabs) do
        if (index > 1) then imgui.SameLine(0, px(data.NAV_GAP)); end

        local selected = (name == ui.active_tab);
        imgui.PushStyleColor(ImGuiCol_Button,
            selected and data.COLOR_NAV_SELECTED or data.COLOR_NAV_IDLE);

        if (imgui.Button(nav_label(name))) then
            ui.active_tab = name;
        end

        imgui.PopStyleColor(1);
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

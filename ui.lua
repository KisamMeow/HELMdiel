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

local WINDOW_BG = { data.SURFACE_BASE[1], data.SURFACE_BASE[2],
                    data.SURFACE_BASE[3], 1 };

local scale = 1.0;

local function px(value)
    return value * scale;
end

-- Text widths
local WIDTH_CAP = 4096;

local width_sizes = {};
local width_face  = nil;
local width_at    = nil;
local width_n     = 0;

local function set_metrics(face, size)
    if (face ~= width_face) then
        width_sizes = {};
        width_face  = face;
        width_n     = 0;
    end

    local bucket = width_sizes[size];
    if (bucket == nil) then bucket = {}; width_sizes[size] = bucket; end
    width_at = bucket;
end

local function measure(text)
    local w = width_at[text];
    if (w == nil) then
        w = imgui.CalcTextSize(text);
        if (width_n >= WIDTH_CAP) then
            for _, bucket in pairs(width_sizes) do
                for key in pairs(bucket) do bucket[key] = nil; end
            end
            width_n = 0;
        end
        width_at[text] = w;
        width_n = width_n + 1;
    end
    return w;
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
    if (a.rank ~= b.rank) then return a.rank < b.rank; end
    if (a.count ~= b.count) then return a.count > b.count; end
    if (a.needs ~= b.needs) then return (a.needs or 0) < (b.needs or 0); end
    return a.name < b.name;
end

local PRICE_ROWS    = nil;
local PRICE_SCANNED = nil;

local function by_activity_then_name(a, b)
    if (a.order ~= b.order) then return a.order < b.order; end
    return a.name < b.name;
end

local function by_profit_then_name(a, b)
    if (a.profit ~= b.profit) then return a.profit > b.profit; end
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
        label = ('%s###nav%s'):fmt(data.NAV_SHORT[name] or name, name);
        NAV_LABELS[name] = label;
    end
    return label;
end

local SPOILS      = T{};
local SPOIL_SLOTS = {};
local TOOLS       = T{};
local TOOL_SLOTS  = {};

local FIRST_SIZE = { 360, 0 };
local TABS       = T{};
local SPOIL_ICON = { 0, 0 };
local BOX_SIZE   = { 0, 0 };
local ART_SIZE   = { 0, 0 };
local LINE_GAP   = { 0, 0 };
local PRICE_BOX  = { 0, 0 };
local SPOIL_BOX  = { 0, 0 };
local spoils_floor = 0;

local STYLE_COLORS;
local STYLE_VARS;

local function window_style()
    if (STYLE_COLORS ~= nil) then return; end

    STYLE_COLORS = T{
        { ImGuiCol_WindowBg,         WINDOW_BG },
        { ImGuiCol_TextDisabled,     data.COLOR_LABEL },
        { ImGuiCol_Border,           data.COLOR_EDGE },
        { ImGuiCol_PopupBg,          data.COLOR_POPUP },
        { ImGuiCol_TextSelectedBg,   data.COLOR_TEXT_SELECT },

        { ImGuiCol_FrameBg,        data.COLOR_INPUT },
        { ImGuiCol_FrameBgHovered, data.COLOR_INPUT_HOVER },
        { ImGuiCol_FrameBgActive,  data.COLOR_INPUT_ACTIVE },
        { ImGuiCol_CheckMark,      data.COLOR_GRAB },
        { ImGuiCol_SliderGrab,     data.COLOR_GRAB },
        { ImGuiCol_SliderGrabActive, data.COLOR_GRAB_ACTIVE },

        { ImGuiCol_ScrollbarBg,          data.COLOR_SCROLL_BG },
        { ImGuiCol_ScrollbarGrab,        data.COLOR_SCROLL },
        { ImGuiCol_ScrollbarGrabHovered, data.COLOR_SCROLL_HOVER },
        { ImGuiCol_ScrollbarGrabActive,  data.COLOR_SCROLL_ACTIVE },

        { ImGuiCol_Separator,        data.COLOR_SEPARATOR },
        { ImGuiCol_SeparatorHovered, data.COLOR_SEPARATOR },
        { ImGuiCol_SeparatorActive,  data.COLOR_SEPARATOR },

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
        { ImGuiStyleVar_WindowBorderSize, data.WINDOW_BORDER },
    };
end

local MIN_SIZE = { 0, 0 };
local MAX_SIZE = { 99999, 99999 };

local title         = 'HELMdiel###HELMdiel';
local title_version = nil;
local title_char    = false;

-- Fonts
local fonts  = {};
local loaded = false;

function ui.load_font()
    if (loaded) then return true; end
    loaded = true;

    local all = true;
    for _, entry in ipairs(data.FONTS) do
        local ok, face = pcall(imgui.AddFontFromFileTTF,
                               data.FONT_DIR .. entry.file, data.FONT_SIZE);
        if (ok and face ~= nil) then
            fonts[entry.name] = face;
        else
            all = false;
        end
    end
    return all;
end

local frame_font = nil;

local function chosen_font()
    return fonts[store.font_name()] or fonts[data.FONT_DEFAULT];
end

function ui.set_actions(handlers)
    actions = handlers;
end

function ui.set_title(version)
    title_version = version;
    title_char    = false;
end

local function window_title(charname)
    if (charname == title_char) then return title; end
    title_char = charname;

    if (title_version == nil) then
        title = 'HELMdiel###HELMdiel';
    elseif (charname == nil or charname == '') then
        title = ('HELMdiel v%s###HELMdiel'):fmt(title_version);
    else
        title = ('HELMdiel v%s - %s###HELMdiel'):fmt(title_version, charname);
    end
    return title;
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
local ONE      = { 0 };

local function tooltip(text)
    if (text:find('%', 1, true) ~= nil) then
        text = text:gsub('%%', '%%%%');
    end
    imgui.SetTooltip(text);
end

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
    RIGHT_POS[1] = right - measure(text);
    RIGHT_POS[2] = top;
    imgui.GetWindowDrawList():AddText(RIGHT_POS,
        imgui.GetColorU32(color), text);
end

local TILE_SIZE = { 0, 0 };
local TILE_PAD  = { 0, 0 };
local TILE_LINE = { 0, 0 };
local TILES     = {};

local function tile(index, label, value, color, tip, a, b, c, d, e)
    local slot = TILES[index];
    if (slot == nil) then slot = {}; TILES[index] = slot; end
    slot.label, slot.value, slot.color, slot.tip = label, value, color, tip;
    slot.a, slot.b, slot.c, slot.d, slot.e = a, b, c, d, e;
    slot.note = nil;
    return slot;
end

local TILE_MIN  = { 0, 0 };
local TILE_MAX  = { 0, 0 };
local tile_fill = nil;

local function tiles_per_row(count)
    if (count > data.TILES_PER_ROW) then return math.ceil(count / 2); end
    return count;
end

local function tile_row_height(count, per, row, base, drop)
    local first = (row - 1) * per + 1;
    for index = first, math.min(count, first + per - 1) do
        if (TILES[index].note ~= nil) then return base + drop; end
    end
    return base;
end

local function paint_tiles(count, x, y, w, base, drop)
    local list  = imgui.GetWindowDrawList();
    local gap   = px(data.TILE_GAP);
    local per   = tiles_per_row(count);
    local width = (w - gap * (per - 1)) / per;
    local padx  = px(data.TILE_PAD_X);
    local pady  = px(data.TILE_PAD_Y);
    local plate = imgui.GetColorU32(data.COLOR_TILE_BG);
    local cap   = imgui.GetColorU32(data.COLOR_CAPTION);
    local gold  = imgui.GetColorU32(data.COLOR_GOLD);

    local mx, my = imgui.GetMousePos();
    local over   = imgui.IsWindowHovered();

    local row, top, tall = 0, y - gap, 0;
    for index = 1, count do
        local slot = TILES[index];
        local at   = math.floor((index - 1) / per) + 1;
        if (at ~= row) then
            top  = top + tall + gap;
            row  = at;
            tall = tile_row_height(count, per, row, base, drop);
        end
        local left = x + (width + gap) * ((index - 1) % per);

        if (over and slot.tip ~= nil
            and mx >= left and mx < left + width
            and my >= top and my < top + tall) then
            local said = slot.tip(slot.a, slot.b, slot.c, slot.d, slot.e);
            if (said ~= nil) then tooltip(said); end
        end

        TILE_MIN[1] = left;
        TILE_MIN[2] = top;
        TILE_MAX[1] = left + width;
        TILE_MAX[2] = top + tall;
        list:AddRectFilled(TILE_MIN, TILE_MAX, plate, px(data.FRAME_ROUNDING));

        TEXT_POS[1] = left + padx;
        TEXT_POS[2] = top + pady;
        clip_text(list, left, left + width, top, top + tall, cap, slot.label);

        TEXT_POS[2] = top + pady + drop;
        clip_text(list, left, left + width, top, top + tall,
            imgui.GetColorU32(slot.color or data.COLOR_VALUE), slot.value);

        if (slot.note ~= nil) then
            TEXT_POS[2] = top + pady + drop * 2;
            clip_text(list, left, left + width, top, top + tall, gold, slot.note);
        end
    end
end

local function lay_out_tiles(count, avail, base, drop)
    local gap = px(data.TILE_GAP);

    TILE_PAD[1] = px(data.TILE_PAD_X);
    TILE_PAD[2] = px(data.TILE_PAD_Y);
    TILE_LINE[1] = 0;
    TILE_LINE[2] = px(data.ITEM_LINE_GAP);

    local per = tiles_per_row(count);

    TILE_SIZE[1] = (avail - gap * (per - 1)) / per;

    imgui.PushStyleColor(ImGuiCol_ChildBg, data.COLOR_TILE_BG);
    imgui.PushStyleVar(ImGuiStyleVar_ChildRounding, px(data.FRAME_ROUNDING));
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, TILE_PAD);
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, TILE_LINE);

    for index = 1, count do
        local column = (index - 1) % per;
        if (column > 0) then
            imgui.SameLine(0, gap);
        else
            TILE_SIZE[2] = tile_row_height(count, per,
                math.floor((index - 1) / per) + 1, base, drop);
        end
        local slot = TILES[index];
        imgui.BeginChild(('##hhtile%d'):fmt(index), TILE_SIZE,
            ImGuiChildFlags_AlwaysUseWindowPadding, ImGuiWindowFlags_NoScrollbar);
        imgui.TextColored(data.COLOR_CAPTION, slot.label);
        imgui.TextColored(slot.color or data.COLOR_VALUE, slot.value);
        if (slot.note ~= nil) then imgui.TextColored(data.COLOR_GOLD, slot.note); end
        imgui.EndChild();
    end

    imgui.PopStyleVar(3);
    imgui.PopStyleColor(1);
end

local function render_tiles(count)
    local avail = imgui.GetContentRegionAvail();
    local drop  = imgui.GetTextLineHeight() + px(data.ITEM_LINE_GAP);
    local base  = imgui.GetTextLineHeight() * 2 + px(data.ITEM_LINE_GAP)
                  + px(data.TILE_PAD_Y) * 2;
    local per   = tiles_per_row(count);
    local rows  = math.ceil(count / per);

    if (tile_fill ~= false) then
        local x, y = imgui.GetCursorScreenPos();
        tile_fill = pcall(paint_tiles, count, x, y, avail, base, drop);
    end

    if (not tile_fill) then
        lay_out_tiles(count, avail, base, drop);
        return;
    end

    local height = (rows - 1) * px(data.TILE_GAP);
    for row = 1, rows do
        height = height + tile_row_height(count, per, row, base, drop);
    end
    TILE_SIZE[1] = 0;
    TILE_SIZE[2] = height;
    imgui.Dummy(TILE_SIZE);
end

local function skill_text(charname, activity)
    local skill = store.get_skill(charname, activity);
    return skill == nil and 'unknown' or ('%.1f'):fmt(skill);
end

local function render_skill_head(charname, activity)
    local head  = activity:upper();
    local text  = skill_text(charname, activity);
    local avail = imgui.GetContentRegionAvail();
    local x, y  = imgui.GetCursorScreenPos();

    imgui.TextColored(data.COLOR_CAPTION, head);

    if (right_fill ~= false) then
        right_fill = pcall(right_text, text, data.COLOR_VALUE, x + avail, y);
    end

    if (not right_fill) then
        local hw = measure(head);
        local vw = measure(text);
        imgui.SameLine(0, math.max(0, avail - hw - vw));
        imgui.TextColored(data.COLOR_VALUE, text);
    end
end

local function as_rate(part, whole)
    if (whole <= 0) then return '-'; end
    return ('%.1f%%'):fmt(part / whole * 100);
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

local BOX_XY   = { 0, 0 };
local BOX_MIN  = { 0, 0 };
local BOX_MAX  = { 0, 0 };
local box_fill = nil;

local function paint_check(x, y, side, on, hot)
    local list = imgui.GetWindowDrawList();
    local r    = px(data.FRAME_ROUNDING);

    BOX_MIN[1], BOX_MIN[2] = x, y;
    BOX_MAX[1], BOX_MAX[2] = x + side, y + side;
    list:AddRectFilled(BOX_MIN, BOX_MAX,
        imgui.GetColorU32(hot and data.COLOR_INPUT_HOVER or data.COLOR_INPUT), r);

    if (on) then
        local pad = px(data.CHECK_INSET);
        BOX_MIN[1], BOX_MIN[2] = x + pad, y + pad;
        BOX_MAX[1], BOX_MAX[2] = x + side - pad, y + side - pad;
        list:AddRectFilled(BOX_MIN, BOX_MAX,
            imgui.GetColorU32(data.COLOR_GRAB), r * 0.5);
    end
end

local CHECK_IDS = {};

local function check_id(label, suffix)
    local group = CHECK_IDS[label];
    if (group == nil) then group = {}; CHECK_IDS[label] = group; end

    local tail = suffix or '';
    local id   = group[tail];
    if (id == nil) then
        id = ('##hhchk%s%s'):fmt(label, tail);
        group[tail] = id;
    end
    return id;
end

local function checkbox(label, on, suffix)
    local side = imgui.GetFrameHeight();
    local x, y = imgui.GetCursorScreenPos();
    local top  = imgui.GetCursorPosY();

    BOX_XY[1], BOX_XY[2] = side, side;
    local hit = imgui.InvisibleButton(check_id(label, suffix), BOX_XY);
    local hot = imgui.IsItemHovered();

    if (box_fill ~= false) then
        box_fill = pcall(paint_check, x, y, side, on, hot);
    end

    imgui.SameLine(0, px(data.CHECK_GAP));
    imgui.SetCursorPosY(top + (side - imgui.GetTextLineHeight()) * 0.5);
    imgui.TextDisabled(label);

    return hit;
end

local function caption(text)
    imgui.Spacing();
    imgui.TextColored(data.COLOR_CAPTION, text);
    imgui.Spacing();
end

local function empty(text)
    imgui.TextColored(data.COLOR_CAPTION, text);
end

local function hint(text)
    if (imgui.IsItemHovered()) then tooltip(text); end
end

local function stat(caption, value, tip, ...)
    imgui.TextColored(data.COLOR_CAPTION, caption);
    local hot = imgui.IsItemHovered();
    imgui.SameLine(0, px(data.CELL_GUTTER) * 0.5);
    imgui.TextColored(data.COLOR_SKILLUP, value);
    if (tip ~= nil and (hot or imgui.IsItemHovered())) then
        tooltip(tip(...));
    end
end

local PROC_PARTS = {};
local REPEAT_NAMES = {};

local function node_pair(activity, zoneId)
    local zones = data.GOLD_RUSH_ITEMS[activity];
    return zones and zones[zoneId] or nil;
end

local function node_ore(ability, zoneId)
    if (ability.node == nil) then return nil; end
    local pair = node_pair(ability.activity, zoneId);
    return pair and pair[ability.node] or nil;
end

local function node_half(pair, name)
    if (pair == nil) then return nil; end
    if (name == pair.rush) then return 'rush'; end
    if (name == pair.lode) then return 'lode'; end
    return nil;
end

local function repeat_note(charname, zoneId)
    local names, count = REPEAT_NAMES, 0;

    for itemName, tally in pairs(store.get_repeats(charname, zoneId)) do
        count = count + 1;
        names[count] = ('%s x%d'):fmt(resources.item_name(itemName), tally);
    end
    for index = count + 1, #names do names[index] = nil; end

    if (count == 0) then
        return 'Nothing has dropped from a node here yet.';
    end

    table.sort(names);
    return ('From nodes here:\n%s\n\n%s'):fmt(
        table.concat(names, '\n', 1, count),
        store.count_repeats()
            and 'Counted in the rates above.'
            or  'Left out of the rates above.');
end

local function render_procs(charname, activity, zoneId, collected, tip)
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
        slot.ability = ability;
        slot.short   = ability.short;
        slot.fired   = fired;
        slot.outof   = outof;
        slot.rate    = outof > 0 and ('%.1f%%'):fmt(fired / outof * 100) or '-';
    end

    if (not shown) then return; end

    for index = 1, #abilities do
        local slot = PROC_PARTS[index];
        stat(slot.short, slot.rate, tip, slot.ability, slot.fired,
             slot.outof, charname, zoneId);
        local ore = node_ore(slot.ability, zoneId);
        if (ore ~= nil) then
            imgui.SameLine(0, px(data.CELL_GUTTER) * 0.5);
            imgui.TextColored(data.COLOR_GOLD, ore);
        end
    end
end

local CHIP_MIN, CHIP_MAX = { 0, 0 }, { 0, 0 };
local head_fill = nil;

local function head_meta(capText, state, nameWidth)
    local list   = imgui.GetWindowDrawList();
    local ax, ay = imgui.GetItemRectMin();
    local bx, by = imgui.GetItemRectMax();

    local pad  = px(data.CHIP_PAD);
    local gap  = px(data.CELL_GUTTER);
    local mid  = ay + (by - ay - imgui.GetTextLineHeight()) * 0.5;
    local capw = measure(capText);

    local group = capw + pad * 2 + gap;
    if ((bx - ax) - imgui.GetFrameHeight() - nameWidth - gap < group) then return; end

    local right = bx - gap;

    CHIP_MIN[1] = right - capw - pad * 2;
    CHIP_MIN[2] = ay + px(data.CHIP_INSET);
    CHIP_MAX[1] = right;
    CHIP_MAX[2] = by - px(data.CHIP_INSET);
    local plate, ink = data.COLOR_CHIP, data.COLOR_LABEL;
    if (state == 2) then
        plate, ink = data.COLOR_CHIP_DONE, data.COLOR_GOLD;
    elseif (state == 1) then
        plate, ink = data.COLOR_CHIP_NEAR, data.COLOR_CHIP_NEAR_INK;
    end

    list:AddRectFilled(CHIP_MIN, CHIP_MAX, imgui.GetColorU32(plate),
        px(data.NAV_BTN_ROUNDING));

    TEXT_POS[1] = CHIP_MIN[1] + pad;
    TEXT_POS[2] = mid;
    list:AddText(TEXT_POS, imgui.GetColorU32(ink), capText);
end

local function render_fatigue(charname, activity, zoneId, zoneName)
    local value = store.get_fatigue(charname, activity, zoneId);
    local cap   = store.fatigue_cap(charname, activity, zoneId);
    local color = get_fatigue_color(value, cap);
    local count = ('%d / %d'):fmt(value, cap);

    local fraction = math.min(1, value / cap);

    local avail = imgui.GetContentRegionAvail();
    local x, y  = imgui.GetCursorScreenPos();

    imgui.TextColored(data.COLOR_VALUE, zoneName);

    if (right_fill ~= false) then
        right_fill = pcall(right_text, count, data.COLOR_LABEL, x + avail, y);
    end

    if (not right_fill) then
        local zw = measure(zoneName);
        local cw = measure(count);
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

local DANGER_SIZE = { 0, 0 };

local function danger_button(label)
    local now   = os.clock();
    local armed = (ui.armed == label)
                  and (now - ui.armed_at) < data.CONFIRM_SECONDS;

    if (ui.armed == label and not armed) then ui.armed = nil; end

    local wide = measure(label);
    local ask  = measure(data.CONFIRM_LABEL);
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

local function success_button(label)
    return tinted_button(label, data.COLOR_SUCCESS,
        data.COLOR_SUCCESS_HOVER, data.COLOR_SUCCESS_ACTIVE);
end

local pip_fill = nil;
local PIP_A, PIP_B, PIP_C = { 0, 0 }, { 0, 0 }, { 0, 0 };

local function paint_pip(x, y, art)
    local list = imgui.GetWindowDrawList();
    local legs = art * data.PIP_RATIO;
    local edge = px(1.5);

    PIP_A[1], PIP_A[2] = x + art - legs - edge, y;
    PIP_B[1], PIP_B[2] = x + art, y;
    PIP_C[1], PIP_C[2] = x + art, y + legs + edge;
    list:AddTriangleFilled(PIP_A, PIP_B, PIP_C,
        imgui.GetColorU32(data.SURFACE_BASE));

    PIP_A[1] = x + art - legs;
    PIP_C[2] = y + legs;
    list:AddTriangleFilled(PIP_A, PIP_B, PIP_C,
        imgui.GetColorU32(data.COLOR_GOLD));
end

local function render_item_icon(item, art)
    if (imgui.BeginChild(next_cell_id(), BOX_SIZE,
                         ImGuiChildFlags_None, ImGuiWindowFlags_NoScrollbar)) then
        local sx, sy;
        if (item.node ~= nil and pip_fill ~= false) then
            sx, sy = imgui.GetCursorScreenPos();
        end
        if (item.icon ~= nil) then
            imgui.Image(item.icon.handle, ART_SIZE);
        else
            imgui.Dummy(ART_SIZE);
        end
        if (sx ~= nil) then pip_fill = pcall(paint_pip, sx, sy, art); end
    end
    imgui.EndChild();
end

local function render_item(item, show_icons, art, text_h)
    imgui.BeginGroup();

    if (show_icons) then
        local top = imgui.GetCursorPosY();

        imgui.SetCursorPosY(top + math.max(0, (text_h - art) * 0.5));
        render_item_icon(item, art);
        imgui.SameLine();
        imgui.SetCursorPosY(top + math.max(0, (art - text_h) * 0.5));
    end

    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, LINE_GAP);

    imgui.BeginGroup();
    imgui.TextColored(item.tier.color, item.name);
    if (item.muted) then
        imgui.TextColored(item.tier.color, item.label);
    elseif (item.gilt) then
        imgui.TextColored(data.COLOR_GOLD, item.label);
    else
        imgui.TextDisabled(item.label);
    end
    imgui.EndGroup();

    imgui.PopStyleVar(1);
    imgui.EndGroup();
end

local SEEN   = {};
local PROVEN = {};

local function render_item_list(log, total, charname, activity, zoneId, proven)
    local known = store.zone_items(activity, zoneId);

    if (total == 0 and #known == 0) then
        empty('  No gathers recorded yet.');
        return;
    end

    local show_icons = store.item_icons();

    local scaled = (store.icon_size() == data.SPOILS_ICON_SIZE) and frame_font ~= nil;
    if (scaled) then
        local small = px(data.FONT_SIZE - data.SMALL_ICON_FONT_DROP);
        imgui.PushFont(frame_font, small);
        set_metrics(frame_font, small);
    end

    local items  = ITEMS;
    local widest = 0;
    local count_n = 0;

    local seen = SEEN;
    for key in pairs(seen) do seen[key] = nil; end

    local got = PROVEN;
    for key in pairs(got) do got[key] = nil; end
    if (proven ~= nil) then
        for itemName in pairs(proven) do got[resources.item_name(itemName)] = true; end
    end

    local pair    = node_pair(activity, zoneId);
    local counted = pair ~= nil and store.count_repeats();
    local lost    = data.BARREN_ITEM[activity];

    for itemName, count in pairs(log) do
        if (itemName ~= lost) then
            local pct  = total > 0 and (count / total * 100) or 0;
            local name = resources.item_name(itemName);
            seen[name] = true;

            local label = ('%.1f%%'):fmt(pct);

            local name_w  = measure(name);
            local label_w = measure(label);
            local text_width = math.max(name_w, label_w);

            if (text_width > widest) then widest = text_width; end

            count_n = count_n + 1;
            local slot = pooled(SLOTS, count_n);
            slot.name   = name;
            slot.count  = count;
            slot.label  = label;
            slot.text_w = text_width;
            slot.tier   = get_rarity_tier(pct);
            slot.rank   = slot.tier.rank;
            slot.needs  = nil;
            slot.muted  = false;
            slot.node   = node_half(pair, name);
            slot.gilt   = counted and slot.node ~= nil;
            slot.icon   = show_icons and icons.texture(resources.item_id(itemName)) or nil;
            items[count_n] = slot;
        end
    end

    local skill = store.get_skill(charname, activity);
    for _, entry in ipairs(known) do
        local shown = resources.item_name(entry.name);
        if (not seen[shown]) then
            local locked = entry.skill;
            if (got[shown] or (locked ~= nil and skill ~= nil and skill >= locked)) then
                locked = nil;
            end
            local label  = locked and ('Locked (%d)'):fmt(locked) or 'Not seen';

            local shown_w = measure(shown);
            local label_w = measure(label);
            local text_width = math.max(shown_w, label_w);
            if (text_width > widest) then widest = text_width; end

            count_n = count_n + 1;
            local slot = pooled(SLOTS, count_n);
            slot.name   = shown;
            slot.count  = 0;
            slot.label  = label;
            slot.text_w = text_width;
            slot.tier   = locked and data.TIER_LOCKED or data.TIER_UNSEEN;
            slot.rank   = slot.tier.rank;
            slot.needs  = locked;
            slot.muted  = true;
            slot.node   = node_half(pair, shown);
            slot.gilt   = false;
            slot.icon   = show_icons and icons.texture(resources.item_id(entry.name)) or nil;
            items[count_n] = slot;
        end
    end
    for index = count_n + 1, #items do items[index] = nil; end

    table.sort(items, by_count_then_name);

    local art     = px(store.icon_size());
    local per_row = store.items_per_row();

    local gap    = px(data.ITEM_LINE_GAP);
    local text_h = imgui.GetTextLineHeight() * 2 + gap;

    LINE_GAP[2] = gap;
    BOX_SIZE[1], BOX_SIZE[2] = art, art;
    ART_SIZE[1], ART_SIZE[2] = art, art;

    local grouped   = store.rarity_groups();
    local last_rank = nil;
    local column    = 0;
    for index, item in ipairs(items) do
        local rank = item.rank;
        if (last_rank == nil or (grouped and rank ~= last_rank)) then
            imgui.Spacing();
            imgui.Spacing();
            column = 0;
        end
        last_rank = rank;

        if (column > 0) then
            local previous = items[index - 1];
            imgui.SameLine(0, widest - previous.text_w + px(data.CELL_GUTTER));
        end

        render_item(item, show_icons, art, text_h);

        column = column + 1;
        if (column >= per_row) then column = 0; end
    end

    if (scaled) then
        imgui.PopFont();
        set_metrics(frame_font, px(data.FONT_SIZE));
    end
end

local function divider()
    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();
end

local function zone_cap_label(charname, activity, zoneId)
    local cap = store.skill_capped(charname, activity, zoneId);
    if (cap == nil) then return nil; end
    return ('Cap (%d)'):fmt(cap);
end

local function stop_note(ability, charname, zoneId)
    local caps = data.SKILL_CAPS[ability.activity];
    local cap  = caps and caps[zoneId];
    if (cap == nil) then
        return ('Reported to stop within %.1f of a zone\'s skill cap.')
            :fmt(ability.stops_near);
    end

    local at    = cap - ability.stops_near;
    local skill = store.get_skill(charname, ability.activity);
    if (skill ~= nil and skill >= at) then
        return ('Reported to stop at %.1f; you are past that.'):fmt(at);
    end

    return ('Reported to stop at %.1f, within %.1f of the cap.')
        :fmt(at, ability.stops_near);
end

local function proc_tip(ability, fired, outof, charname, zoneId)
    local head;
    if (outof <= 0) then
        head = ('%s\nNothing has given it a chance to fire yet.')
            :fmt(ability.name);
    else
        local outof_what = ability.basis == 'breaks'
            and 'tools that would have broken' or 'gathers';
        head = ('%s\n%d of %d %s, %.1f%% - every session')
            :fmt(ability.name, fired, outof, outof_what, fired / outof * 100);
    end

    local ore = node_ore(ability, zoneId);
    if (ore ~= nil) then
        head = ('%s\n%s'):fmt(head, ability.node == 'lode'
            and ('Upgrades the node to %s.'):fmt(ore)
            or  ('The node repeats %s.'):fmt(ore));
    end

    if (ability.stops_near ~= nil) then
        head = ('%s\n%s'):fmt(head, stop_note(ability, charname, zoneId));
    end

    if (not ability.repeats) then return head; end
    return ('%s\n\n%s'):fmt(head, repeat_note(charname, zoneId));
end

local function items_tip(total)
    return ('%d item%s here. Every rate below divides this.')
        :fmt(total, total == 1 and '' or 's');
end

local function skillup_tip(ups, swings, cap_at)
    if (cap_at ~= nil) then
        return ('Caps at %d. Swings here are not counted.'):fmt(cap_at);
    end

    if (swings == 0) then
        return 'Nothing swung here yet.';
    end

    return ('%d skill up%s in %d swing%s, %.2f%%.'):fmt(
        ups, ups == 1 and '' or 's',
        swings, swings == 1 and '' or 's', ups / swings * 100);
end

local function render_activity(charname, activity, curZoneId, zoneName)
    local log   = store.get_session_log(charname, activity, curZoneId);
    local total = count_gathers(log);
    local ever  = store.get_item_log(charname, activity, curZoneId);
    local kept  = count_gathers(ever);

    local mode = store.home_mode();

    render_skill_head(charname, activity);
    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();

    render_fatigue(charname, activity, curZoneId, zoneName);

    if (mode == 'Compact') then return; end

    local ups    = store.get_skillups(charname, activity, curZoneId);
    local swings = store.get_attempts(charname, activity, curZoneId);
    local capped = zone_cap_label(charname, activity, curZoneId);
    local since  = store.get_since_skillup(charname, activity);

    tile(1, 'COLLECTED', ('%d'):fmt(total));
    tile(2, 'LAST SKILL', capped or ('%d'):fmt(since), data.COLOR_SKILLUP,
         skillup_tip, ups, swings,
         store.skill_capped(charname, activity, curZoneId));

    local abilities = data.PROC_ABILITIES[activity];
    for index, ability in ipairs(abilities) do
        local fired = store.get_proc(charname, ability.name, curZoneId);
        local outof = kept;
        if (ability.basis == 'breaks') then
            outof = fired + store.get_breaks(charname, activity, curZoneId);
        end
        local slot = tile(2 + index, ability.short, as_rate(fired, outof), nil,
                          proc_tip, ability, fired, outof, charname, curZoneId);
        slot.note = node_ore(ability, curZoneId);
    end

    render_tiles(2 + #abilities);

    if (mode == 'Normal') then imgui.Spacing(); return; end

    imgui.Spacing();
    render_item_list(log, total, charname, activity, curZoneId, ever);
    imgui.Spacing();
end

local function render_home(charname, curZoneId)
    local tracked = data.ZONE_ACTIVITIES[curZoneId];

    imgui.Spacing();
    if (tracked == nil or #tracked == 0) then
        empty('No HELM activity is tracked in this zone.');
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
    if (hours > 0 and mins > 0) then return ('%dhr and %dmin'):fmt(hours, mins); end
    if (hours > 0) then return ('%dhr'):fmt(hours); end
    if (mins > 0) then return ('%dmin'):fmt(mins); end
    return ('%dsec'):fmt(seconds);
end

local function gil(value)
    value = math.floor(value);
    if (value < 0) then return '-' .. gil(-value); end

    local text = tostring(value);
    local head = #text % 3;
    if (head == 0) then head = 3; end

    local out = text:sub(1, head);
    for index = head + 1, #text, 3 do
        out = out .. ',' .. text:sub(index, index + 2);
    end
    return out;
end

local PRICE_BUFFER = {};
local VENDOR_HINT  = 'On: a vendor price. Off: an auction house one.\n'
                  .. 'Zone rates show every drop sold to an NPC in brackets.';

local function price_rows()
    local scanned = resources.scan_done();
    if (PRICE_ROWS ~= nil and PRICE_SCANNED == scanned) then return PRICE_ROWS; end

    local rows = {};
    for order, activity in ipairs(data.PRICE_BLOCKS) do
        for _, key in ipairs(store.priced_items(activity)) do
            rows[#rows + 1] = {
                key      = key,
                name     = resources.item_name(key),
                activity = activity,
                order    = order,
                legacy   = data.LEGACY_SET[activity][key] == true,
                id       = ('##hhprice%s%s'):fmt(activity, key),
            };
        end
    end
    table.sort(rows, by_activity_then_name);

    PRICE_ROWS, PRICE_SCANNED = rows, scanned;
    return rows;
end

local IMPORT_LABEL = "Import Starter Prices";
local IMPORT_POPUP = '##hhimport';
local IMPORT_HINT  = 'Starter prices and Vendor marks, as a place to start.';

local function render_import_popup()
    if (not imgui.BeginPopupModal(IMPORT_POPUP, nil,
            ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_AlwaysAutoResize)) then
        return;
    end

    imgui.TextColored(data.COLOR_CAPTION, 'IMPORT PRICES');
    imgui.Spacing();
    imgui.TextColored(data.COLOR_VALUE, 'Import the starter prices and Vendor marks?');
    imgui.TextDisabled('Import All replaces every price and mark on the list.');
    imgui.TextDisabled('Unpriced Only fills just the items still at 0.');
    imgui.Spacing();

    if (tinted_button('Import All', data.COLOR_DANGER,
            data.COLOR_DANGER_HOVER, data.COLOR_DANGER_ACTIVE)) then
        actions.import_prices(false);
        imgui.CloseCurrentPopup();
    end
    imgui.SameLine(0, px(data.NAV_GAP));
    if (imgui.Button('Unpriced Only')) then
        actions.import_prices(true);
        imgui.CloseCurrentPopup();
    end
    imgui.SameLine(0, px(data.NAV_GAP));
    if (imgui.Button('Cancel')) then
        imgui.CloseCurrentPopup();
    end

    imgui.EndPopup();
end

local function render_price_editor()
    imgui.TextDisabled('Set what each item sells for, and what a tool costs to replace.');
    imgui.Spacing();

    PRICE_BOX[1] = 0;
    PRICE_BOX[2] = px(data.PRICE_EDITOR_HEIGHT);
    imgui.BeginChild('##hhprices', PRICE_BOX, ImGuiChildFlags_Borders);

    local show_icons = store.item_icons();
    SPOIL_ICON[1] = px(data.SPOILS_ICON_SIZE);
    SPOIL_ICON[2] = SPOIL_ICON[1];

    local rows = price_rows();

    local widest = 0;
    for _, slot in ipairs(rows) do
        slot.name_w = measure(slot.name);
        if (slot.name_w > widest) then widest = slot.name_w; end
    end

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

        if (item.legacy) then
            imgui.TextColored(data.COLOR_CAPTION, item.name);
            hint('On the wiki, never seen by this addon.');
        else
            imgui.TextDisabled(item.name);
        end
        imgui.SameLine(0, widest - item.name_w + px(data.CELL_GUTTER));

        if (resources.price_key(item.key) == nil) then
            imgui.TextColored(data.COLOR_HIGH, '(?)');
        else
            PRICE_BUFFER[1] = store.get_price(item.activity, item.key);
            if (imgui.InputInt(item.id, PRICE_BUFFER, 0, 0)) then
                store.set_price(item.activity, item.key, PRICE_BUFFER[1]);
            end
            if (item.activity ~= data.TOOL_KEY) then
                imgui.SameLine(0, px(data.CELL_GUTTER));
                if (checkbox('Vendor', store.is_vendor(item.key), item.id)) then
                    store.toggle_vendor(item.key);
                end
                hint(VENDOR_HINT);
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
    if (resources.scan_done() and store.starter() ~= nil) then
        if (imgui.Button(IMPORT_LABEL)) then
            imgui.OpenPopup(IMPORT_POPUP);
        end
        hint(IMPORT_HINT);
    end
    render_import_popup();
    imgui.Spacing();
end

local function rate_tip(net, tools, span)
    local head = ('%s Gil less %s of tools.'):fmt(gil(net + tools), gil(tools));

    if (span <= 0) then
        return ('%s\nNet %s Gil. Not enough time yet to rate it.')
            :fmt(head, gil(net));
    end
    return ('%s\nNet %s over %s.'):fmt(head, gil(net), span_label(span));
end

local function lifetime_tip()
    return 'Everything gathered, less tools broken.\n'
        .. "Today's prices, so it moves when you change one.";
end

local function render_spoils(charname)
    if (ui.editing_prices) then
        render_price_editor();
        return;
    end

    local spoils     = store.get_spoils(charname);
    local show_icons = store.item_icons();
    local left       = imgui.GetCursorScreenPos();

    imgui.Spacing();

    local hide    = store.hide_vendor();
    local total   = 0;
    local items   = SPOILS;
    local widest  = 0;
    local widestc = 0;
    local n       = 0;
    local shown   = 0;
    for itemName, count in pairs(spoils) do
        n = n + 1;
        local slot = pooled(SPOIL_SLOTS, n);
        slot.key    = itemName;
        slot.name   = resources.item_name(itemName);
        slot.count  = count;
        slot.name_w = measure(slot.name);
        slot.profit = count * store.price_of(itemName);
        slot.gil    = gil(slot.profit);
        slot.vendor = store.is_vendor(itemName);
        slot.tally  = ('x%d'):fmt(count);
        slot.tally_w = measure(slot.tally);
        slot.hidden = hide and slot.vendor;
        items[n] = slot;
        total = total + slot.profit;

        if (not slot.hidden) then
            shown = shown + 1;
            if (slot.name_w > widest)   then widest  = slot.name_w; end
            if (slot.tally_w > widestc) then widestc = slot.tally_w; end
        end
    end
    for index = n + 1, #items do items[index] = nil; end

    local tools = TOOLS;
    local t     = 0;
    for _, activity in ipairs(data.ACTIVITIES) do
        local broke = store.get_tool_breaks(charname, activity);
        if (broke > 0) then
            local name = data.ACTIVITY_TOOLS[activity];
            local slot;
            for index = 1, t do
                if (tools[index].name == name) then slot = tools[index]; break; end
            end
            if (slot == nil) then
                t = t + 1;
                slot = pooled(TOOL_SLOTS, t);
                slot.name    = name;
                slot.count   = 0;
                slot.cost    = 0;
                slot.name_w  = measure(name);
                tools[t] = slot;
            end
            slot.count = slot.count + broke;
            slot.cost  = slot.cost + broke * store.tool_price(activity);
        end
    end
    for index = t + 1, #tools do tools[index] = nil; end

    for index = 1, t do
        local slot = tools[index];
        slot.tally   = ('x%d'):fmt(slot.count);
        slot.tally_w = measure(slot.tally);
        slot.gil     = gil(-slot.cost);
        if (slot.name_w > widest)   then widest  = slot.name_w; end
        if (slot.tally_w > widestc) then widestc = slot.tally_w; end
    end

    local lifetime, ever = store.lifetime_gil(charname);

    if (n > 0) then
        if (checkbox('Hide Vendor Items', hide)) then
            store.toggle_hide_vendor();
        end
        hint('Hides Vendor items from the list. They still count towards '
          .. 'the total.');
    end

    if (n > 0 or ever) then
        local spent = store.tool_cost(charname);
        local net   = total - spent;
        local span  = store.session_span(charname);
        local rate  = span > 0 and net * data.SECONDS_PER_HOUR / span or nil;

        imgui.Spacing();
        tile(1, 'GIL/HR', rate and gil(rate) or '-', data.COLOR_SKILLUP,
             rate_tip, net, spent, span);
        tile(2, 'LIFETIME', gil(lifetime), data.COLOR_SKILLUP, lifetime_tip);
        render_tiles(2);
        imgui.Spacing();
    end

    if (n == 0 and t == 0) then
        empty('Nothing gathered this session.');
    else
        table.sort(items, by_profit_then_name);

        SPOIL_ICON[1] = px(data.SPOILS_ICON_SIZE);
        SPOIL_ICON[2] = SPOIL_ICON[1];

        local head  = data.SPOILS_HEADERS;
        local head1 = measure(head[1]);
        local head2 = measure(head[2]);
        if (head1 > widest)  then widest  = head1; end
        if (head2 > widestc) then widestc = head2; end

        if (show_icons) then
            imgui.Dummy(SPOIL_ICON);
            imgui.SameLine(0, px(data.SPOILS_ICON_GAP));
        end
        imgui.TextColored(data.COLOR_CAPTION, head[1]);
        imgui.SameLine(0, widest - head1 + px(data.CELL_GUTTER));
        imgui.TextColored(data.COLOR_CAPTION, head[2]);
        imgui.SameLine(0, widestc - head2 + px(data.CELL_GUTTER));
        imgui.TextColored(data.COLOR_CAPTION, head[3]);
        imgui.Separator();
        imgui.Spacing();

        if (n > 0 and shown == 0) then
            empty('Every item here is marked Vendor.');
        end

        local scroll = shown > data.SPOILS_SCROLL_AFTER;
        if (scroll) then
            local widestg = 0;
            for _, item in ipairs(items) do
                if (not item.hidden) then
                    local w = measure(item.gil);
                    if (w > widestg) then widestg = w; end
                end
            end

            local pitch = imgui.GetTextLineHeightWithSpacing();
            local line  = imgui.GetTextLineHeight();
            if (SPOIL_ICON[2] > line) then pitch = pitch + SPOIL_ICON[2] - line; end

            local columns = (show_icons and (SPOIL_ICON[1] + px(data.SPOILS_ICON_GAP)) or 0)
                          + widest + widestc + widestg + px(data.CELL_GUTTER) * 2
                          + px(data.SCROLLBAR_WIDTH);
            local narrowest = px(data.WINDOW_MIN_WIDTH) - px(data.WINDOW_PADDING) * 2;
            SPOIL_BOX[1] = math.max(columns, spoils_floor, narrowest);
            SPOIL_BOX[2] = pitch * data.SPOILS_SCROLL_AFTER;
            imgui.BeginChild('##hhspoils', SPOIL_BOX, ImGuiChildFlags_None);
        end

        for _, item in ipairs(items) do
            if (not item.hidden) then
                if (show_icons) then
                    local icon = icons.texture(resources.item_id(item.key));
                    if (icon ~= nil) then
                        imgui.Image(icon.handle, SPOIL_ICON);
                    else
                        imgui.Dummy(SPOIL_ICON);
                    end
                    imgui.SameLine(0, px(data.SPOILS_ICON_GAP));
                end

                local ink = item.vendor and data.COLOR_LABEL or data.COLOR_VALUE;
                imgui.TextColored(ink, item.name);
                imgui.SameLine(0, widest - item.name_w + px(data.CELL_GUTTER));
                imgui.TextColored(ink, item.tally);
                imgui.SameLine(0, widestc - item.tally_w + px(data.CELL_GUTTER));
                imgui.TextColored(data.COLOR_SKILLUP, item.gil);
            end
        end

        if (scroll) then imgui.EndChild(); end

        if (t > 0) then
            imgui.Spacing();
            imgui.Separator();
            imgui.Spacing();

            for _, tool in ipairs(tools) do
                if (show_icons) then
                    local icon = icons.texture(resources.item_id(tool.name));
                    if (icon ~= nil) then
                        imgui.Image(icon.handle, SPOIL_ICON);
                    else
                        imgui.Dummy(SPOIL_ICON);
                    end
                    imgui.SameLine(0, px(data.SPOILS_ICON_GAP));
                end

                imgui.TextColored(data.COLOR_LABEL, tool.name);
                imgui.SameLine(0, widest - tool.name_w + px(data.CELL_GUTTER));
                imgui.TextColored(data.COLOR_LABEL, tool.tally);
                imgui.SameLine(0, widestc - tool.tally_w + px(data.CELL_GUTTER));
                imgui.TextColored(data.COLOR_COST, tool.gil);
            end
        end
    end

    divider();

    if (imgui.Button('Edit Prices')) then
        ui.editing_prices = true;
    end
    imgui.SameLine(0, px(data.NAV_GAP));
    if (success_button('Export Session')) then
        actions.export_spoils();
    end
    hint('Writes this tab to a spreadsheet, tools included.');
    imgui.SameLine(0, px(data.NAV_GAP));
    if (danger_button('Reset Session')) then
        store.reset_spoils();
    end
    hint('Clears only this tab.');
    spoils_floor = imgui.GetItemRectMax() - left;
    imgui.Spacing();
end

local function repeat_caveat(charname, zoneId)
    if (store.count_repeats()) then return nil; end
    if (next(store.get_repeats(charname, zoneId)) == nil) then return nil; end
    return 'Repeats not counted, so this reads high.';
end

local PRE_GROSS, PRE_COST, PRE_VENDOR, PRE_UNKNOWN = {}, {}, {}, {};

local function gil_hour_tip(each, pace, span, timed, total, charname, zoneId, unknown)
    if (pace == nil) then
        return ('%d of %d gathers timed here.\nThe clock runs between gathers '
             .. 'and stops when you leave.'):fmt(timed, data.PACE_MIN);
    end

    local head = ('%.0f an hour, %s a gather, timed here.\n'
               .. '%d of %d gathers timed, over %s.')
        :fmt(pace, gil(each), timed, total, span_label(span));

    if (unknown ~= nil and unknown > 0) then
        head = ('%s\nNo NPC price for %d drop%s here, so brackets read low.')
            :fmt(head, unknown, unknown == 1 and '' or 's');
    end

    local caveat = repeat_caveat(charname, zoneId);
    if (caveat == nil) then return head; end
    return ('%s\n%s'):fmt(head, caveat);
end

local function gil_each_tip(gross, cost, total, charname, activity, zoneId)
    local each = (gross - cost) / total;
    local run  = store.fatigue_cap(charname, activity, zoneId);

    return ('%s Gil over %d gather%s, less %s of tools.\n'
         .. 'A full %d run is worth about %s.\n'
         .. "Today's prices, so it moves when you change one.")
        :fmt(gil(gross), total, total == 1 and '' or 's', gil(cost),
             run, gil(each * run));
end

local function render_activity_tab(charname, activity)
    local zones = data.TRACKED_ZONES[activity];

    render_skill_head(charname, activity);
    imgui.Spacing();
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
        empty('No fatigue recorded.');
        imgui.Spacing();
    end

    imgui.Separator();
    imgui.Spacing();

    local caps  = data.SKILL_CAPS[activity];
    local skill = store.get_skill(charname, activity) or 0;

    local best_id, best, rated = nil, 0, 0;
    local next_id, next_best   = nil, 0;
    for _, zone in ipairs(zones) do
        PRE_GROSS[zone.id] = nil;
        local rate = store.zone_pace(charname, activity, zone.id);
        if (rate ~= nil) then
            local total = count_gathers(store.get_item_log(charname, activity, zone.id));
            local gross, cost, vendor, unknown = store.zone_gil(charname, activity, zone.id);
            PRE_GROSS[zone.id], PRE_COST[zone.id] = gross, cost;
            PRE_VENDOR[zone.id], PRE_UNKNOWN[zone.id] = vendor, unknown;
            if (total > 0 and gross > 0) then
                rated = rated + 1;
                local hour = (gross - cost) / total * rate;
                if (hour > best) then
                    next_best, next_id = best, best_id;
                    best, best_id = hour, zone.id;
                elseif (hour > next_best) then
                    next_best, next_id = hour, zone.id;
                end
            end
        end
    end
    if (rated < 2) then best_id, next_id = nil, nil; end

    for _, zone in ipairs(zones) do
        local log   = store.get_item_log(charname, activity, zone.id);
        local total = count_gathers(log);
        local capAt = store.skill_capped(charname, activity, zone.id);
        local cap   = caps and caps[zone.id];

        local state = 0;
        if (capAt ~= nil) then
            state = 2;
        elseif (cap ~= nil and (cap - skill) <= data.CAP_NEAR) then
            state = 1;
        end

        local capText = cap ~= nil and ('CAP %d'):fmt(cap) or nil;

        local label = zone.name;
        if (head_fill == false and capText ~= nil) then
            label = ('%s - %s'):fmt(label, capText);
        end

        local bare = total == 0;
        local top  = zone.id == best_id;
        local near = zone.id == next_id;
        local tint = (bare and data.COLOR_CAPTION) or (top and data.COLOR_GOLD)
                  or (near and data.COLOR_RUNNER_UP) or nil;
        if (tint) then imgui.PushStyleColor(ImGuiCol_Text, tint); end
        local open = imgui.CollapsingHeader(('%s###hh%s%d'):fmt(label, activity, zone.id));
        if (tint) then imgui.PopStyleColor(1); end

        if (top and imgui.IsItemHovered()) then
            tooltip(('Best gil an hour of %d timed zones: %s.'):fmt(rated, gil(best)));
        elseif (near and imgui.IsItemHovered()) then
            tooltip(('Second best gil an hour of %d timed zones: %s.')
                :fmt(rated, gil(next_best)));
        end

        if (head_fill ~= false and capText ~= nil) then
            local name_w = measure(zone.name);
            head_fill = pcall(head_meta, capText, state, name_w);
        end

        if (open) then
            local ups    = store.get_skillups(charname, activity, zone.id);
            local swings = store.get_attempts(charname, activity, zone.id);

            local first = true;
            if (total > 0) then
                stat('ITEMS', ('%d'):fmt(total), items_tip, total);
                first = false;
            end

            if (capAt == nil and swings > 0) then
                if (not first) then imgui.SameLine(0, px(data.STAT_GAP)); end
                stat('SKILL UPS', ('%.1f%%'):fmt(ups / swings * 100),
                     skillup_tip, ups, swings, nil);
            end

            render_procs(charname, activity, zone.id, total, proc_tip);

            local gross, cost, vendor, unknown;
            if (PRE_GROSS[zone.id] ~= nil) then
                gross, cost = PRE_GROSS[zone.id], PRE_COST[zone.id];
                vendor, unknown = PRE_VENDOR[zone.id], PRE_UNKNOWN[zone.id];
            else
                gross, cost, vendor, unknown = store.zone_gil(charname, activity, zone.id);
            end
            if (gross > 0) then
                local each = (gross - cost) / total;
                local sold = (vendor - cost) / total;

                local rate, span, timed = store.zone_pace(charname, activity, zone.id);

                local shown = '-';
                if (rate ~= nil) then
                    shown = gil(each * rate);
                    local vendored = gil(sold * rate);
                    if (vendored ~= shown) then
                        shown = ('%s (%s)'):fmt(shown, vendored);
                    end
                end

                stat('GIL/HR', shown, gil_hour_tip, each, rate, span, timed,
                     total, charname, zone.id, unknown);
                imgui.SameLine(0, px(data.STAT_GAP));
                stat('PER GATHER', gil(each), gil_each_tip,
                     gross, cost, total, charname, activity, zone.id);
            end

            imgui.Spacing();
            imgui.Separator();
            imgui.Spacing();

            render_item_list(log, total, charname, activity, zone.id);
            imgui.Spacing();
        end
    end
end

-- Activities, two per row
local function activity_pairs()
    local widest = 0;
    for _, activity in ipairs(data.ACTIVITIES) do
        local width = measure(activity);
        if (width > widest) then widest = width; end
    end
    return widest;
end

local function render_settings(charname)
    local widest = activity_pairs();

    caption('DISPLAY');

    imgui.PushItemWidth(px(data.COMBO_WIDTH));
    ONE[1] = store.font_index() - 1;
    local fonted = ONE;
    if (imgui.Combo('Font', fonted, data.FONT_COMBO)) then
        store.set_font_index(fonted[1] + 1);
    end
    imgui.PopItemWidth();
    hint('Typeface for the window. All ship with Windows.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.COMBO_WIDTH));
    ONE[1] = store.home_mode_index() - 1;
    local homed = ONE;
    if (imgui.Combo('Home Detail', homed, data.HOME_MODE_COMBO)) then
        store.set_home_mode_index(homed[1] + 1);
    end
    imgui.PopItemWidth();
    hint('Full: everything. Normal: no item list.\n'
         .. 'Compact: skill and fatigue only.');

    imgui.Spacing();

    if (checkbox('Item Icons', store.item_icons())) then
        store.toggle_item_icons();
    end
    hint('Show item art beside drop counts.');

    imgui.Spacing();

    if (checkbox('Large Item Size', store.large_items())) then
        store.toggle_large_items();
    end
    hint('Off: smaller item art and text.');

    imgui.Spacing();

    if (checkbox('2 Column Style', store.list_items())) then
        store.toggle_list_items();
    end
    hint('Two items to a row. Off: three.');

    imgui.Spacing();

    if (checkbox('Group by Rarity', store.rarity_groups())) then
        store.toggle_rarity_groups();
    end
    hint('Off: one run ordered by drop rate, no gaps.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.SLIDER_WIDTH));
    ONE[1] = store.window_opacity();
    local opacity = ONE;
    if (imgui.SliderFloat('Opacity', opacity, data.OPACITY_MIN, data.OPACITY_MAX, '%.2f')) then
        store.set_window_opacity(opacity[1]);
    end
    imgui.PopItemWidth();
    hint('Window background.');

    imgui.Spacing();

    imgui.PushItemWidth(px(data.COMBO_WIDTH));
    ONE[1] = store.ui_scale_index() - 1;
    local chosen = ONE;
    if (imgui.Combo('UI Scale', chosen, data.UI_SCALE_COMBO)) then
        store.set_ui_scale_index(chosen[1] + 1);
    end
    imgui.PopItemWidth();
    hint('Size of text, icons and spacing.');

    caption('ACTIVITIES');
    imgui.TextDisabled('Shown activities');
    imgui.Spacing();

    for index, activity in ipairs(data.ACTIVITIES) do
        if (checkbox(activity, store.activity_enabled(activity), '##show')) then
            store.toggle_activity(activity);
        end
        if (index % 2 == 1) then
            imgui.SameLine(0, widest - measure(activity) + px(data.CELL_GUTTER));
        end
    end

    caption('SKILL LEVELS');
    imgui.TextDisabled('Skill levels');
    imgui.Spacing();

    imgui.PushItemWidth(px(data.SKILL_INPUT_WIDTH));
    for index, activity in ipairs(data.ACTIVITIES) do
        ONE[1] = store.get_skill(charname, activity) or 0;
        local buffer = ONE;
        if (imgui.InputFloat(activity, buffer, 0, 0, '%.1f')) then
            store.set_skill(charname, activity, math.max(0, buffer[1]));
            store.save();
        end
        if (index % 2 == 1) then
            imgui.SameLine(0, widest - measure(activity) + px(data.CELL_GUTTER));
        end
    end
    imgui.PopItemWidth();

    caption('TRACKING');

    if (checkbox('Count Gold Rush/Motherlode Drops', store.count_repeats())) then
        store.toggle_count_repeats();
    end
    hint('Gold Rush repeats an item, Motherlode upgrades it.\n'
         .. 'Off keeps repeats out of your drop rates.');

    imgui.Spacing();

    if (checkbox('Auto-Open on Gather', store.auto_popup())) then
        store.toggle_auto_popup();
    end
    hint('Shows the window when you gather.');

    imgui.Spacing();

    if (checkbox('Auto-Show Activity', store.auto_show())) then
        store.toggle_auto_show();
    end
    hint('Brings a hidden activity back when you gather one.');

    imgui.Spacing();

    if (checkbox('Auto-Resize Window', store.auto_resize())) then
        store.toggle_auto_resize();
    end
    hint('Off: drag the gold corner to resize.');

    caption('EXPORT');

    if (success_button('Export CSV')) then
        actions.export();
    end
    hint('Writes a spreadsheet beside your settings.');

    imgui.Spacing();

    if (checkbox('Minimum Data', store.export_minimal())) then
        store.toggle_export_minimal();
    end
    hint('Drops your name and personal counters.');

    caption('RESET');

    if (danger_button('Reset Gather/Skill Ups')) then
        actions.reset_session();
    end
    hint('Clears gather and skill up counters.');

    imgui.Spacing();

    if (danger_button('Reset All Data')) then
        actions.reset_all();
    end
    hint('Clears everything for this character but skill levels.');
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

local SHEEN_MIN  = { 0, 0 };
local SHEEN_MAX  = { 0, 0 };
local sheen_fill = nil;

local function window_sheen(x, y, w)
    local list = imgui.GetWindowDrawList();
    local top  = imgui.GetColorU32(data.COLOR_SHEEN);
    local fade = imgui.GetColorU32(data.COLOR_SHEEN_END);

    SHEEN_MIN[1] = x;
    SHEEN_MIN[2] = y;
    SHEEN_MAX[1] = x + w;
    SHEEN_MAX[2] = y + px(data.SHEEN_HEIGHT);

    list:AddRectFilledMultiColor(SHEEN_MIN, SHEEN_MAX, top, top, fade, fade);
end

local NAV_MIN  = { 0, 0 };
local NAV_MAX  = { 0, 0 };
local NAV_CLOSE_MIN = { 0, 0 };
local NAV_CLOSE_MAX = { 0, 0 };
local NAV_ROOM = { 0, 0 };
local NAV_DOT_MIN = { 0, 0 };
local NAV_DOT_MAX = { 0, 0 };
local NAV_ARM_A   = { 0, 0 };
local NAV_ARM_B   = { 0, 0 };
local NAV_BTN_PAD = { 0, 0 };
local NAV_TIGHT   = { 0, 0 };
local NAV_PAD_ROW = { 0, 0 };
local nav_close_hot = false;
local nav_track_h   = 0;

local function nav_grip_width()
    return px(data.NAV_DOT) * 2 + px(data.NAV_DOT_GAP);
end

local function nav_close_width()
    return px(data.NAV_CLOSE_SIZE) + px(data.NAV_EDGE_PAD) * 2;
end
local nav_fill = nil;

local function nav_track(x, y, w, h)
    NAV_MIN[1] = x;
    NAV_MIN[2] = y;
    NAV_MAX[1] = x + w;
    NAV_MAX[2] = y + h;

    local list = imgui.GetWindowDrawList();
    list:AddRectFilled(NAV_MIN, NAV_MAX,
        imgui.GetColorU32(data.COLOR_NAV_TRACK), px(data.FRAME_ROUNDING));

    local pad = px(data.NAV_EDGE_PAD);
    local mid = y + h * 0.5;

    local dot  = px(data.NAV_DOT);
    local step = dot + px(data.NAV_DOT_GAP);
    local top  = mid - (dot * 3 + px(data.NAV_DOT_GAP) * 2) * 0.5;
    local ink  = imgui.GetColorU32(data.COLOR_CAPTION);
    for col = 0, 1 do
        for row = 0, 2 do
            NAV_DOT_MIN[1] = x + pad + col * step;
            NAV_DOT_MIN[2] = top + row * step;
            NAV_DOT_MAX[1] = NAV_DOT_MIN[1] + dot;
            NAV_DOT_MAX[2] = NAV_DOT_MIN[2] + dot;
            list:AddRectFilled(NAV_DOT_MIN, NAV_DOT_MAX, ink, 0);
        end
    end

    local room = nav_close_width();
    NAV_CLOSE_MIN[1] = x + w - room;
    NAV_CLOSE_MIN[2] = y;
    NAV_CLOSE_MAX[1] = x + w;
    NAV_CLOSE_MAX[2] = y + h;

    local mx, my = imgui.GetMousePos();
    nav_close_hot = imgui.IsWindowHovered()
        and mx >= NAV_CLOSE_MIN[1] and mx < NAV_CLOSE_MAX[1]
        and my >= NAV_CLOSE_MIN[2] and my < NAV_CLOSE_MAX[2];

    local arm = px(data.NAV_CLOSE_SIZE) * 0.5;
    local cx  = x + w - pad - arm;
    local thick = px(data.NAV_CLOSE_WEIGHT);
    local cross = imgui.GetColorU32(
        nav_close_hot and data.COLOR_VALUE or data.COLOR_LABEL);

    NAV_ARM_A[1] = cx - arm; NAV_ARM_A[2] = mid - arm;
    NAV_ARM_B[1] = cx + arm; NAV_ARM_B[2] = mid + arm;
    list:AddLine(NAV_ARM_A, NAV_ARM_B, cross, thick);

    NAV_ARM_A[1] = cx - arm; NAV_ARM_A[2] = mid + arm;
    NAV_ARM_B[1] = cx + arm; NAV_ARM_B[2] = mid - arm;
    list:AddLine(NAV_ARM_A, NAV_ARM_B, cross, thick);
end

local function render_nav(tabs)
    local showing = false;
    for _, name in ipairs(tabs) do
        if (name == ui.active_tab) then showing = true; break; end
    end
    if (not showing) then ui.active_tab = tabs[1]; end

    NAV_BTN_PAD[1] = px(data.NAV_BTN_PAD_X);
    NAV_BTN_PAD[2] = px(data.NAV_BTN_PAD_Y);
    imgui.PushStyleVar(ImGuiStyleVar_FramePadding, NAV_BTN_PAD);
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, px(data.NAV_BTN_ROUNDING));
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, NAV_TIGHT);

    local pad = px(data.NAV_TRACK_PAD);
    nav_track_h = imgui.GetFrameHeight() + pad * 2;

    if (nav_fill ~= false) then
        local x, y = imgui.GetCursorScreenPos();
        nav_fill = pcall(nav_track, x, y, imgui.GetContentRegionAvail(),
                                          nav_track_h);
    end

    if (nav_fill and nav_close_hot and imgui.IsMouseClicked(0)) then
        ui.visible = false;
    end

    if (nav_fill) then
        NAV_PAD_ROW[1] = 0;
        NAV_PAD_ROW[2] = pad;
        imgui.Dummy(NAV_PAD_ROW);
        imgui.SetCursorPosX(imgui.GetCursorPosX()
            + nav_grip_width() + px(data.NAV_EDGE_PAD) * 2);
    end

    imgui.PushStyleColor(ImGuiCol_ButtonHovered, data.COLOR_NAV_HOVER);
    imgui.PushStyleColor(ImGuiCol_ButtonActive,  data.COLOR_NAV_ACTIVE);

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

    imgui.PopStyleColor(2);

    if (nav_fill) then
        imgui.SameLine(0, px(data.NAV_GAP));
        NAV_ROOM[1] = nav_close_width();
        NAV_ROOM[2] = 1;
        imgui.Dummy(NAV_ROOM);

        NAV_PAD_ROW[1] = 0;
        NAV_PAD_ROW[2] = pad;
        imgui.Dummy(NAV_PAD_ROW);
    end

    imgui.PopStyleVar(3);
end

function ui.render(charname, curZoneId)
    resources.scan_chunk();

    if (not ui.visible) then return; end

    window_style();
    cell_id      = 0;
    scale        = store.ui_scale();
    WINDOW_BG[4] = store.window_opacity();
    MIN_SIZE[1]  = px(data.WINDOW_MIN_WIDTH);

    for _, entry in ipairs(STYLE_COLORS) do
        imgui.PushStyleColor(entry[1], entry[2]);
    end
    for _, entry in ipairs(STYLE_VARS) do
        imgui.PushStyleVar(entry[1], entry[2]);
    end

    frame_font = chosen_font();
    if (frame_font ~= nil) then imgui.PushFont(frame_font, px(data.FONT_SIZE)); end
    set_metrics(frame_font, px(data.FONT_SIZE));

    imgui.SetNextWindowSize(FIRST_SIZE, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowSizeConstraints(MIN_SIZE, MAX_SIZE);

    local flags = ImGuiWindowFlags_NoTitleBar;
    if (store.auto_resize()) then
        flags = flags + ImGuiWindowFlags_AlwaysAutoResize;
    end

    if (imgui.Begin(window_title(charname), nil, flags)) then
        if (sheen_fill ~= false) then
            local sx, sy = imgui.GetCursorScreenPos();
            sheen_fill = pcall(window_sheen, sx, sy,
                               imgui.GetContentRegionAvail());
        end

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

    if (frame_font ~= nil) then imgui.PopFont(); end

    imgui.PopStyleVar(#STYLE_VARS);
    imgui.PopStyleColor(#STYLE_COLORS);
end

return ui;

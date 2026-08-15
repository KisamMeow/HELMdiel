require('common');

local data      = require('data');
local store     = require('store');
local resources = require('resources');

local export = T{};

local NEWLINE = '\r\n';

-- RFC 4180: quote only when the value could otherwise break the row, and
-- double any quote inside it. clean_item_name currently strips commas and
-- quotes out of item names, so nothing needs it today. It costs one compare
-- per field to stay correct if that ever changes.
local function field(value)
    if (value == nil) then return ''; end

    local text = tostring(value);
    if (text:find('[",\r\n]') == nil) then return text; end

    return '"' .. text:gsub('"', '""') .. '"';
end

-- Counted against the header rather than walked with ipairs. Skill is nil
-- until the first skill up, and a nil ends a Lua array, so ipairs would emit
-- a row one column short and silently shift every value after it in the
-- spreadsheet. This way a missing value is an empty cell and every row has
-- exactly as many fields as the header.
local function row(values)
    local out = T{};
    for index = 1, #data.EXPORT_HEADER do
        table.insert(out, field(values[index]));
    end
    return table.concat(out, ',');
end

local function count_items(log)
    local total = 0;
    for _, count in pairs(log) do
        total = total + count;
    end
    return total;
end

-- One row per item, with its zone's figures repeated alongside. That shape
-- pivots directly in a spreadsheet, which a section per activity would not.
-- A zone with counters but nothing logged still gets a row, with the item
-- columns blank, so turning fatigue into a row never loses it.
function export.build(charname)
    local lines = T{ row(data.EXPORT_HEADER) };

    for _, activity in ipairs(data.ACTIVITIES) do
        local skill = store.get_skill(charname, activity);

        for _, zone in ipairs(data.TRACKED_ZONES[activity]) do
            local log       = store.get_item_log(charname, activity, zone.id);
            local gathers   = count_items(log);
            local fatigue   = store.get_fatigue(charname, activity, zone.id);
            local attempts  = store.get_attempts(charname, activity, zone.id);
            local successes = store.get_successes(charname, activity, zone.id);
            local skillups  = store.get_skillups(charname, activity, zone.id);

            -- The displayed inventory name, not the chat-log key the log is
            -- stored under, so the spreadsheet reads the way the game and
            -- the window do.
            local items = T{};
            for name, count in pairs(log) do
                table.insert(items, {
                    name  = resources.item_name(name),
                    count = count,
                });
            end

            -- pairs() order is not stable between runs, so sort or two
            -- exports of identical data would not diff against each other.
            table.sort(items, function(a, b)
                if (a.count ~= b.count) then return a.count > b.count; end
                return a.name < b.name;
            end);

            if (#items == 0) then
                if (fatigue > 0 or attempts > 0 or gathers > 0) then
                    table.insert(lines, row(T{ charname, activity, zone.name,
                        '', '', 0, '', fatigue, attempts, successes, skillups,
                        skill }));
                end
            else
                for _, item in ipairs(items) do
                    local rate = ('%.1f'):fmt(item.count / gathers * 100);
                    table.insert(lines, row(T{ charname, activity, zone.name,
                        item.name, item.count, gathers, rate, fatigue,
                        attempts, successes, skillups, skill }));
                end
            end
        end
    end

    return table.concat(lines, NEWLINE) .. NEWLINE, #lines - 1;
end

function export.write(charname)
    local path = ('%s%s_export.csv'):fmt(store.config_path(), charname);

    local ok, handle = pcall(io.open, path, 'w');
    if (not ok or handle == nil) then return false, path, 0; end

    local text, rows = export.build(charname);

    handle:write(text);
    handle:close();

    return true, path, rows;
end

return export;

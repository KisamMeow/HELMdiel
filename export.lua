require('common');

local data      = require('data');
local store     = require('store');
local resources = require('resources');

local export = T{};

local NEWLINE     = '\r\n';
local SHARED_STEM = 'HELMdiel';

local function field(value)
    if (value == nil) then return ''; end

    local text = tostring(value);
    if (text:find('[",\r\n]') == nil) then return text; end

    return '"' .. text:gsub('"', '""') .. '"';
end

local function row(header, record)
    local out = T{};
    for _, column in ipairs(header) do
        table.insert(out, field(record[column]));
    end
    return table.concat(out, ',');
end

local function header_row(header)
    local out = T{};
    for _, column in ipairs(header) do
        table.insert(out, field(column));
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

function export.build(charname, minimal)
    local header = minimal and data.EXPORT_HEADER_MIN or data.EXPORT_HEADER;
    local lines  = T{ header_row(header) };

    for _, activity in ipairs(data.ACTIVITIES) do
        local skill = store.get_skill(charname, activity);

        for _, zone in ipairs(data.TRACKED_ZONES[activity]) do
            local log       = store.get_item_log(charname, activity, zone.id);
            local gathers   = count_items(log);
            local fatigue   = store.get_fatigue(charname, activity, zone.id);
            local attempts  = store.get_attempts(charname, activity, zone.id);
            local successes = store.get_successes(charname, activity, zone.id);
            local skillups  = store.get_skillups(charname, activity, zone.id);

            local items = T{};
            for name, count in pairs(log) do
                table.insert(items, {
                    name  = resources.item_name(name),
                    count = count,
                });
            end

            table.sort(items, function(a, b)
                if (a.count ~= b.count) then return a.count > b.count; end
                return a.name < b.name;
            end);

            local zone_row = {
                ['Character']    = charname,
                ['Activity']     = activity,
                ['Zone']         = zone.name,
                ['Zone Gathers'] = gathers,
                ['Fatigue']      = fatigue,
                ['Attempts']     = attempts,
                ['Successes']    = successes,
                ['Skill Ups']    = skillups,
                ['Skill']        = skill,
            };

            if (#items == 0) then
                if (not minimal and (fatigue > 0 or attempts > 0 or gathers > 0)) then
                    table.insert(lines, row(header, zone_row));
                end
            else
                for _, item in ipairs(items) do
                    zone_row['Item']      = item.name;
                    zone_row['Count']     = item.count;
                    zone_row['Drop Rate'] = ('%.1f'):fmt(item.count / gathers * 100);
                    table.insert(lines, row(header, zone_row));
                end
            end
        end
    end

    return table.concat(lines, NEWLINE) .. NEWLINE, #lines - 1;
end

function export.write(charname)
    local minimal = store.export_minimal();
    local path    = ('%s%s_export.csv'):fmt(store.config_path(),
                                            minimal and SHARED_STEM or charname);

    local ok, handle = pcall(io.open, path, 'w');
    if (not ok or handle == nil) then return false, path, 0; end

    local text, rows = export.build(charname, minimal);

    handle:write(text);
    handle:close();

    return true, path, rows;
end

return export;

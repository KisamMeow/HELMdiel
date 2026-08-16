require('common');

local data = require('data');

local detect = T{};

local function resolve_from(patterns, text, zoneId)
    local fallback_activity, fallback_pattern = nil, nil;

    for _, activity in ipairs(data.ACTIVITIES) do
        for _, pattern in ipairs(patterns[activity]) do
            if (text:find(pattern, 1, true)) then
                if (data.TRACKED_ZONE_SET[activity][zoneId]) then
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

local CODE_BYTES = '[\30\31\127]';

function detect.has_codes(text)
    return text:find(CODE_BYTES) ~= nil;
end

function detect.strip_codes(text)
    return (text:gsub(CODE_BYTES .. '.', ''));
end

function detect.gather(text, zoneId)
    return resolve_from(data.MESSAGE_PATTERNS, text, zoneId);
end

function detect.failure(text, zoneId)
    return resolve_from(data.FAILURE_PATTERNS, text, zoneId);
end

function detect.barren(text, zoneId)
    return resolve_from(data.BARREN_PATTERNS, text, zoneId);
end

function detect.tool_break(text, zoneId)
    return resolve_from(data.BREAK_PATTERNS, text, zoneId);
end

function detect.proc(text, zoneId)
    local activity, pattern = resolve_from(data.PROC_PATTERNS, text, zoneId);
    if (activity == nil) then return nil, nil; end
    return activity, data.PROC_NAMES[pattern];
end

function detect.is_fatigue_message(text)
    return text:find(data.FATIGUE_PATTERN, 1, true) ~= nil;
end

function detect.fatigued_activity(zoneId, lastActivity)
    local tracked = data.ZONE_ACTIVITIES[zoneId];

    if (tracked ~= nil and #tracked == 1) then
        return tracked[1];
    end

    if (tracked ~= nil and lastActivity ~= nil) then
        for _, activity in ipairs(tracked) do
            if (activity == lastActivity) then return activity; end
        end
        return nil;
    end

    return lastActivity;
end

function detect.skill(text)
    if (not text:find(data.SKILL_MARKER, 1, true)) then return nil, nil; end

    for _, activity in ipairs(data.ACTIVITIES) do
        if (text:find(data.SKILL_PATTERNS[activity], 1, true)) then
            local value = tonumber(text:match(data.SKILL_VALUE_DECIMAL))
                       or tonumber(text:match(data.SKILL_VALUE_INTEGER));
            if (value ~= nil) then
                return activity, value;
            end
        end
    end
    return nil, nil;
end

function detect.extract_after(text, prefix)
    local _, stop = text:find(prefix, 1, true);
    if (stop == nil) then return nil; end

    local rest = text:sub(stop + 1):gsub('^%s+', ''):gsub('%s+$', ''):gsub('%.$', '');
    if (rest == '') then return nil; end
    return rest;
end

function detect.clean_item_name(name)
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

return detect;

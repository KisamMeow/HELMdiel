require('common');

local data = require('data');

local resources = T{};

local ZONE_NAMES      = T{};
local ITEM_NAMES      = T{};
local ITEM_IDS        = T{};
local ITEM_IDS_BY_NAME = T{};

local ITEM_LOOKUP     = T{};
local ITEM_SCAN_CHUNK = 1500;
local ITEM_SCAN_MAX   = 65535;
local item_scan_next  = 1;
local item_scan_done  = false;

for id, label in pairs(data.ZONE_LABELS) do
    ZONE_NAMES[id] = label;
end

function resources.zone_name(zoneId)
    local name = ZONE_NAMES[zoneId];
    if (name ~= nil) then return name; end

    local ok, resolved = pcall(function()
        return AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
    end);
    if (not ok or resolved == nil or resolved == '') then
        resolved = ('Zone %d'):fmt(zoneId);
    end

    ZONE_NAMES[zoneId] = resolved;
    return resolved;
end

local function item_key(text)
    if (type(text) ~= 'string') then return ''; end
    return (text:lower():gsub('%p', ' '):gsub('%s+', ' '):match('^%s*(.-)%s*$') or '');
end

local function first_string(field)
    if (field == nil) then return nil; end
    for index = 1, 4 do
        local value = field[index];
        if (type(value) == 'string' and value ~= '') then return value; end
    end
    return nil;
end

local function index_item(item)
    local shown = first_string(item.Name);
    if (shown == nil) then return; end

    local id = item.Id;

    local logged = item_key(first_string(item.LogNameSingular));
    if (logged ~= '' and ITEM_LOOKUP[logged] == nil) then
        ITEM_LOOKUP[logged] = shown;
        ITEM_IDS[logged]    = id;
    end

    local named = item_key(shown);
    if (named ~= '' and ITEM_LOOKUP[named] == nil) then
        ITEM_LOOKUP[named] = shown;
        ITEM_IDS[named]    = id;
    end
end

function resources.scan_chunk()
    if (item_scan_done) then return; end

    local manager = AshitaCore:GetResourceManager();
    if (manager == nil) then item_scan_done = true; return; end

    local lookup = manager.GetItemById;
    local last   = math.min(item_scan_next + ITEM_SCAN_CHUNK - 1, ITEM_SCAN_MAX);

    for id = item_scan_next, last do
        local ok, item = pcall(lookup, manager, id);
        if (ok and item ~= nil) then
            pcall(index_item, item);
        end
    end

    item_scan_next = last + 1;
    if (last >= ITEM_SCAN_MAX) then item_scan_done = true; end
end

function resources.item_name(name)
    local cached = ITEM_NAMES[name];
    if (cached ~= nil) then return cached; end

    local bare  = name:gsub('^[Aa]n?%s+', '');
    local shown = ITEM_LOOKUP[item_key(bare)] or (bare:gsub('^%l', string.upper));

    if (item_scan_done) then
        ITEM_NAMES[name] = shown;
    end
    return shown;
end

function resources.item_id(name)
    local cached = ITEM_IDS_BY_NAME[name];
    if (cached ~= nil) then
        if (cached == false) then return nil; end
        return cached;
    end

    local bare = name:gsub('^[Aa]n?%s+', '');
    local id   = ITEM_IDS[item_key(bare)];

    if (item_scan_done) then
        ITEM_IDS_BY_NAME[name] = id or false;
    end
    return id;
end

function resources.item_bitmap(id)
    local manager = AshitaCore:GetResourceManager();
    if (manager == nil) then return nil, nil; end

    local ok, item = pcall(manager.GetItemById, manager, id);
    if (not ok or item == nil) then return nil, nil; end

    return item.Bitmap, item.ImageSize;
end

return resources;

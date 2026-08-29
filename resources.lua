require('common');

local data = require('data');

local resources = T{};

local ZONE_NAMES      = T{};
local ITEM_NAMES      = T{};
local ITEM_IDS        = T{};
local ITEM_IDS_BY_NAME = T{};
local PRICE_KEYS      = T{};

local ITEM_LOOKUP     = T{};
local ITEM_SCAN_CHUNK = 500;
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

-- Moon phase

local moon_at, moon_pct, moon_seen = nil, nil, -1;
local moon_base, moon_ok = nil, nil;

local function moon_pointer()
    if (moon_base ~= nil) then return moon_base; end
    if (moon_ok == false) then return nil; end

    local mem = ashita and ashita.memory;
    if (mem == nil or mem.find == nil) then moon_ok = false; return nil; end

    local ok, found = pcall(mem.find, 'FFXiMain.dll', 0, data.MOON_SIGNATURE,
                            data.MOON_POINTER_OFFSET, 0);
    if (not ok or found == nil or found == 0) then moon_ok = false; return nil; end

    moon_base = found;
    return moon_base;
end

local function read_moon()
    local base = moon_pointer();
    if (base == nil) then return nil; end

    local mem = ashita.memory;
    local ok, pointer = pcall(mem.read_uint32, base);
    if (not ok or pointer == nil or pointer == 0) then return nil; end

    local got, ticks = pcall(mem.read_uint32, pointer + data.MOON_TIME_OFFSET);
    if (not got or ticks == nil) then return nil; end

    local day    = math.floor((ticks + data.MOON_EPOCH) / data.MOON_DAY_TICKS);
    local mphase = (day + 26) % data.MOON_CYCLE;
    local away   = math.abs(data.MOON_HALF - mphase);
    return data.MOON_INDEX[mphase + 1],
           math.floor(away * 100 / data.MOON_HALF + 0.5);
end

function resources.moon_phase()
    local now = os.clock();
    if (moon_at ~= nil and (now - moon_seen) < data.MOON_CACHE_SECONDS) then
        return moon_at, moon_pct;
    end

    moon_at, moon_pct = read_moon();
    moon_seen = now;
    return moon_at, moon_pct;
end

function resources.target_node()
    local memory = AshitaCore:GetMemoryManager();
    if (memory == nil) then return nil; end

    local target = memory:GetTarget();
    local entity = memory:GetEntity();
    if (target == nil or entity == nil) then return nil; end

    local index = target:GetTargetIndex(0);
    if (index == nil or index == 0) then return nil; end

    return index, entity:GetServerId(index);
end

function resources.node_gone(index, serverId)
    local memory = AshitaCore:GetMemoryManager();
    if (memory == nil) then return false; end

    local entity = memory:GetEntity();
    if (entity == nil) then return false; end

    if (entity:GetServerId(index) ~= serverId) then return true; end

    local flags = entity:GetRenderFlags0(index) or 0;
    return math.floor(flags / data.RENDER_VISIBLE) % 2 == 0;
end

function resources.scan_done()
    return item_scan_done;
end

local function resolve(name)
    local bare  = name:gsub('^[Aa]n?%s+', '');
    local key   = item_key(bare);
    local alias = data.ITEM_ALIASES[key];
    if (alias == nil) then return bare, key; end
    return alias, item_key(alias);
end

function resources.item_name(name)
    local cached = ITEM_NAMES[name];
    if (cached ~= nil) then return cached; end

    local bare, key = resolve(name);
    local shown = ITEM_LOOKUP[key] or (bare:gsub('^%l', string.upper));

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

    local _, key = resolve(name);
    local id     = ITEM_IDS[key];

    if (item_scan_done) then
        ITEM_IDS_BY_NAME[name] = id or false;
    end
    return id;
end

-- The price key: either name form resolves to the same item id
function resources.price_key(name)
    local id = resources.item_id(name);
    if (id == nil) then return nil; end

    local key = PRICE_KEYS[id];
    if (key == nil) then
        key = tostring(id);
        PRICE_KEYS[id] = key;
    end
    return key;
end

function resources.item_bitmap(id)
    local manager = AshitaCore:GetResourceManager();
    if (manager == nil) then return nil, nil; end

    local ok, item = pcall(manager.GetItemById, manager, id);
    if (not ok or item == nil) then return nil, nil; end

    return item.Bitmap, item.ImageSize;
end

return resources;

require('common');

local resources = require('resources');

local icons = T{};

local CACHE   = T{};
local MISSING = false;

local d3d8, ffi, device;
local ready = nil;

local function start()
    if (ready ~= nil) then return ready; end

    local ok_d3d8, mod_d3d8 = pcall(require, 'd3d8');
    local ok_ffi,  mod_ffi  = pcall(require, 'ffi');

    if (not ok_d3d8 or not ok_ffi or mod_d3d8 == nil or mod_ffi == nil) then
        ready = false;
        return ready;
    end

    d3d8 = mod_d3d8;
    ffi  = mod_ffi;

    local ok_device, resolved = pcall(d3d8.get_device);
    if (not ok_device or resolved == nil) then
        ready = false;
        return ready;
    end

    device = resolved;
    ready  = true;
    return ready;
end

local function create(id)
    local bitmap, bytes = resources.item_bitmap(id);
    if (bitmap == nil) then return nil; end

    local size = -1;
    if (ashita.interface_version == nil) then
        size = bytes;
    end

    local out = ffi.new('IDirect3DTexture8*[1]');

    local created = ffi.C.D3DXCreateTextureFromFileInMemoryEx(
        device, bitmap, size,
        0xFFFFFFFF, 0xFFFFFFFF, 1, 0,
        ffi.C.D3DFMT_A8R8G8B8, ffi.C.D3DPOOL_MANAGED,
        ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0xFF000000,
        nil, nil, out);

    if (created ~= ffi.C.S_OK) then return nil; end

    local texture = d3d8.gc_safe_release(ffi.cast('IDirect3DTexture8*', out[0]));

    local ok, desc = texture:GetLevelDesc(0);
    if (ok ~= 0) then return nil; end

    return T{
        handle = tonumber(ffi.cast('uint32_t', texture)),
        texture = texture,
        width  = desc.Width,
        height = desc.Height,
    };
end

function icons.texture(id)
    if (id == nil) then return nil; end

    local cached = CACHE[id];
    if (cached ~= nil) then
        if (cached == MISSING) then return nil; end
        return cached;
    end

    if (not start()) then
        CACHE[id] = MISSING;
        return nil;
    end

    local ok, built = pcall(create, id);
    if (not ok or built == nil) then
        CACHE[id] = MISSING;
        return nil;
    end

    CACHE[id] = built;
    return built;
end

return icons;

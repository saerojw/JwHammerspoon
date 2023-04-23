local function combinations(objects, n)
    local samples = {}
    local N = #objects
    if (1 < n) and (n < N) then
        local remainder = {table.unpack(objects)}
        for i = 1, N do
            local first_choose = table.remove(remainder, 1)
            local sub_samples = combinations(remainder, n-1)
            for j, sub_sample in pairs(sub_samples) do
                local sample = concat({first_choose}, sub_sample)
                table.insert(samples, sample)
            end
        end
    elseif (n == 1) then
        for i = 1, N do
            table.insert(samples, {objects[i]})
        end
    elseif (n == N) then
        table.insert(samples, objects)
    end
    return samples
end


local function getMods(mods)
    local kc_mods = {}
    local hk_cond = {}
    local ret_cond = false
    for _, mod in ipairs(mods) do
        if string.find(mod,'left')~=nil then
            table.insert(kc_mods, string.sub(mod, 5, #mod))
            ret_cond = true
        elseif string.find(mod, 'right')~=nil then
            table.insert(kc_mods, string.sub(mod, 6, #mod))
            ret_cond = true
        else
            table.insert(kc_mods, mod)
        end
        table.insert(hk_cond, mod)
    end
    if not ret_cond then
        hk_cond = {}
    end
    return kc_mods, hk_cond
end


-- hs.eventtap.keyStroke(modifiers, character[, delay, application])
-- hs.eventtap.keyStrokes(text[, application])
local function keyStroke(src_mods, src_key, tgt_mods, tgt_key)
    local pressedfn, releasedfn, repeatfn
    if hs.keycodes.map[tgt_key]==nil then
        assert(#tgt_mods==0)
        pressedfn = function() hs.eventtap.keyStrokes(tgt_key, 1000) end
        releasedfn = nil
        repeatfn = pressedfn
    elseif src_key==tgt_key then
        assert(src_mods~=tgt_mods)
        pressedfn = function() hs.eventtap.keyStroke(tgt_mods, tgt_key, 1000) end
        releasedfn = pressedfn
        repeatfn = nil
    else
        pressedfn = function() hs.eventtap.keyStroke(tgt_mods, tgt_key, 1000) end
        releasedfn = nil
        repeatfn = pressedfn
    end
    return pressedfn, releasedfn, repeatfn
end


HK_CONDS = {}
-- hs.hotkey.bind(mods, key, [message,] pressedfn, releasedfn, repeatfn)
-- hs.hotkey.new(mods, key, [message,] pressedfn, releasedfn, repeatfn):enable()
function remap(cond_kc_mods, src_key, ...)
    assert(type(cond_kc_mods)=='table' and type(src_key)=='string' and #{...}<4)
    local src_mods, hk_cond = getMods(cond_kc_mods)
    local tgt_kc_mods, tgt_mods, tgt_key, expand_kc_mods
    local pressedfn, releasedfn, repeatfn = ...
    if not (type(pressedfn)=='function' or type(releasedfn)=='function' or type(repeatfn)=='function') then
        tgt_kc_mods, tgt_key, expand_kc_mods = pressedfn, releasedfn, repeatfn
        tgt_mods = getMods(tgt_kc_mods)
        pressedfn, releasedfn, repeatfn = keyStroke(src_mods, src_key, tgt_mods, tgt_key)
    end

    if #hk_cond==0 then
        hs.hotkey.bind(src_mods, src_key, pressedfn, releasedfn, repeatfn)
    else
        local hotkey = hs.hotkey.new(src_mods, src_key, pressedfn, releasedfn, repeatfn)
        local hk_cond_id = table.concat(hk_cond, ' ')
        if HK_CONDS[hk_cond_id] then
            table.insert(HK_CONDS[hk_cond_id], hotkey)
        else
            HK_CONDS[hk_cond_id] = {hotkey}
        end
    end

    if type(expand_kc_mods)=='table' then
        for n = 1, #expand_kc_mods do
            for _, comb_kc_mods in ipairs(combinations(expand_kc_mods, n)) do
                src_mods, hk_cond = getMods(concat(cond_kc_mods, comb_kc_mods))
                tgt_mods = getMods(concat(tgt_kc_mods, comb_kc_mods))
                if #hk_cond==0 then
                    hs.hotkey.bind(src_mods, src_key, keyStroke(src_mods, src_key, tgt_mods, tgt_key))
                else
                    local hotkey = hs.hotkey.new(src_mods, src_key, keyStroke(src_mods, src_key, tgt_mods, tgt_key))
                    local hk_cond_id = table.concat(hk_cond, ' ')
                    if HK_CONDS[hk_cond_id] then
                        table.insert(HK_CONDS[hk_cond_id], hotkey)
                    else
                        HK_CONDS[hk_cond_id] = {hotkey}
                    end
                end
            end
        end
    end
end

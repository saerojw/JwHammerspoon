local function combinations(objects, r)
    local samples = {}
    local n = #objects
    if (1 < r) and (r < n) then
        local remainder = {table.unpack(objects)}
        for i = 1, n do
            local first_choose = table.remove(remainder, 1)
            local sub_samples = combinations(remainder, r-1)
            for j, sub_sample in pairs(sub_samples) do
                local sample = concatenate({first_choose}, sub_sample)
                table.insert(samples, sample)
            end
        end
    elseif (r == 1) then
        for i = 1, n do
            table.insert(samples, {objects[i]})
        end
    elseif (r == n) then
        table.insert(samples, objects)
    end
    return samples
end


-- hs.eventtap.keyStroke(modifiers, character[, delay, application])
function keyStroke(mods, key)
	if key == nil then
		key = mods
		mods = {}
	end
	return function() hs.eventtap.keyStroke(mods, key, 1000) end
end


-- hs.hotkey.bind(mods, key, [message,] pressedfn, releasedfn, repeatfn)
-- hs.hotkey.new(mods, key, [message,] pressedfn, releasedfn, repeatfn):enable()
function remap(mods, key, pressFn)
	hs.hotkey.bind(mods, key, pressFn, nil, pressFn)
end


-- apply other modifiers to hotkey
-- "mods" is extended to include combinations of "options" called "opt_mods".
-- "tgtArgsFn" is a function to determine how "opt_mods" is applied to "pressedFn".
-- e.g., "modsConcat" concatenates "opt_mods" with "mods" for "pressedFn".
function remap_ex(mods, key, pressedFn, pressedFnArgs, tgtArgsFn, options)
    remap(mods, key, pressedFn(table.unpack(pressedFnArgs)))
    for r = 1, #options do
        for _, opt_mods in ipairs(combinations(options, r)) do
            local src_mods = concatenate(mods, opt_mods)
            local tgt_args = tgtArgsFn(pressedFnArgs, opt_mods)
            remap(src_mods, key, pressedFn(table.unpack(tgt_args)))
        end
    end
end


function modsConcat(mods_key, opt_mods)
    local mods, key = table.unpack(mods_key)
    if key==nil then
        key = mods
        mods = {}
    end
    return {concatenate(mods, opt_mods), key}
end


function notApply(mods_key, opt_mods)
    return mods_key
end


function modsReplace(mods_key, opt_mods)
    local mods, key = table.unpack(mods_key)
    return {opt_mods, key}
end
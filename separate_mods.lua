local KC_MODS = {'cmd', 'ctrl', 'alt', 'shift', 'rightcmd', 'rightctrl', 'rightalt', 'rightshift',
                  cmd=1, ctrl=2, alt=3, shift=4, rightcmd=5, rightctrl=6, rightalt=7, rightshift=8}

local function reset()
    for _, kc_mod in ipairs(KC_MODS) do
        MODS[kc_mod].beenPressedAlone = false
    end
end

local function pressed(mod)
    return MODS[mod].isPressed
end

local function pressedAny(mods)
    local ret = false
    for _, mod in ipairs(mods) do
        ret = ret or MODS[mod].isPressed
    end
    return ret
end

local function pressedAll(mods)
    local ret = true
    for _, mod in ipairs(mods) do
        ret = ret and MODS[mod].isPressed
    end
    return ret
end

local function pressedExactly(mods)
    local ret = true
    for _, kc_mod in ipairs(KC_MODS) do
        local in_mods = false
        for _, mod in ipairs(mods) do
            if kc_mod == mod then
                in_mods = true
                break
            end
        end
        if (not in_mods and MODS[kc_mod].isPressed) or (in_mods and not MODS[kc_mod].isPressed) then
            ret  = false
            break
        end
    end
    return ret
end

local function get_state(kc_mod)
    local state = {[true] ={[true]='pressedAlone', [false]='pressed' },
                   [false]={[true]='tapped',       [false]='released'}}
    return state[MODS[kc_mod].isPressed][MODS[kc_mod].beenPressedAlone]
end

local function condition(keycode, kc_mod, state)
    return keycode==kc_mod and MODS.get_state(kc_mod)==state
end

local function update(event)
    local keycode = hs.keycodes.map[event:getKeyCode()]
    local flags = event:getFlags()

    if KC_MODS[keycode] then
        for _, mod in ipairs({'cmd', 'ctrl', 'alt', 'shift'}) do
            if flags[mod] then  -- mod is pressed
                if keycode==mod then
                    MODS[mod].isPressed = not MODS[mod].isPressed
                    MODS[mod].beenPressedAlone = not MODS['right'..mod].isPressed and flags:containExactly({mod})
                    MODS['right'..mod].beenPressedAlone = not MODS[mod].isPressed and flags:containExactly({mod})
                elseif keycode=='right'..mod then
                    MODS['right'..mod].isPressed = not MODS['right'..mod].isPressed
                    MODS[mod].beenPressedAlone = not MODS['right'..mod].isPressed and flags:containExactly({mod})
                    MODS['right'..mod].beenPressedAlone = not MODS[mod].isPressed and flags:containExactly({mod})
                else
                    MODS[mod].beenPressedAlone = false
                    MODS['right'..mod].beenPressedAlone = false
                end
            else
                MODS[mod].isPressed = false
                MODS['right'..mod].isPressed = false
            end
        end
    else
        MODS.reset()
    end
    return keycode
end


function separated_mods_FLAGS()
    MODS = {}
    for _, kc_mod in ipairs(KC_MODS) do
        MODS[kc_mod] = {isPressed=false, beenPressedAlone=false}
    end
    MODS.reset = reset
    MODS.pressed = pressed
    MODS.pressedAny = pressedAny
    MODS.pressedAll = pressedAll
    MODS.pressedExactly = pressedExactly
    MODS.get_state = get_state
    MODS.update = update
    MODS.condition = condition
    MODS.keycodes = KC_MODS
    return MODS
end

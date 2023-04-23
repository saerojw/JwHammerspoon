local KC_MODS = {'cmd', 'ctrl', 'alt', 'shift',
                 'rightcmd', 'rightctrl', 'rightalt', 'rightshift',
                 'leftcmd', 'leftctrl', 'leftalt', 'leftshift',
                  cmd=1, ctrl=2, alt=3, shift=4,
                  rightcmd=5, rightctrl=6, rightalt=7, rightshift=8,
                  leftcmd=9, leftctrl=10, leftalt=11, leftshift=12}

local function getState(kc_mod)
    local state = {[true] ={[true]='pressedAlone', [false]='pressed' },
                   [false]={[true]='tapped',       [false]='released'}}
    return state[MODS[kc_mod].isPressed][MODS[kc_mod].beenPressedAlone]
end


MODS = {}
for _, kc_mod in ipairs(KC_MODS) do
    MODS[kc_mod] = {isPressed=false, beenPressedAlone=false}
end
MODS.keycodes = KC_MODS


function MODS.reset()
    for _, kc_mod in ipairs(KC_MODS) do
        MODS[kc_mod].beenPressedAlone = false
    end
end


function MODS.update(event)
    local keycode = hs.keycodes.map[event:getKeyCode()]
    local flags = event:getFlags()

    if KC_MODS[keycode] then
        for _, mod in ipairs({'cmd', 'ctrl', 'alt', 'shift'}) do
            if flags[mod] then  -- mod is pressed
                if keycode==mod then
                    MODS['left'..mod].isPressed = not MODS['left'..mod].isPressed
                    MODS['left'..mod].beenPressedAlone = not MODS['right'..mod].isPressed and flags:containExactly({mod})
                    MODS['right'..mod].beenPressedAlone = not MODS['left'..mod].isPressed and flags:containExactly({mod})
                elseif keycode=='right'..mod then
                    MODS['right'..mod].isPressed = not MODS['right'..mod].isPressed
                    MODS['right'..mod].beenPressedAlone = not MODS['left'..mod].isPressed and flags:containExactly({mod})
                    MODS['left'..mod].beenPressedAlone = not MODS['right'..mod].isPressed and flags:containExactly({mod})
                else
                    MODS['left'..mod].beenPressedAlone = false
                    MODS['right'..mod].beenPressedAlone = false
                end
            else
                MODS['left'..mod].isPressed = false
                MODS['right'..mod].isPressed = false
            end
            MODS[mod].isPressed = MODS['left'..mod].isPressed or MODS['right'..mod].isPressed
            MODS[mod].beenPressedAlone = MODS['left'..mod].beenPressedAlone or MODS['right'..mod].beenPressedAlone
        end
    else
        MODS.reset()
    end
    return keycode
end


function MODS.pressed(mod)
    return MODS[mod].isPressed
end


function MODS.pressedAny(mods)
    local ret = false
    for _, mod in ipairs(mods) do
        ret = ret or MODS[mod].isPressed
    end
    return ret
end


function MODS.pressedAll(mods)
    local ret = true
    for _, mod in ipairs(mods) do
        ret = ret and MODS[mod].isPressed
    end
    return ret
end


function MODS.pressedExactly(mods)
    local t = {}
    for i, mod in ipairs(mods) do
        t[mod] = KC_MODS[mod]
        if string.find(mod, 'left') then
            t[string.sub(mod, 5, #mod)] = KC_MODS[mod]
        elseif string.find(mod, 'right') then
            t[string.sub(mod, 6, #mod)] = KC_MODS[mod]
        else
            t['left'..mod] = KC_MODS[mod]
            t['right'..mod] = KC_MODS[mod]
        end
    end
    local ok = true
    for _, kc_mod in ipairs(KC_MODS) do
        if t[kc_mod] then
            ok = ok and MODS[KC_MODS[t[kc_mod]]].isPressed
        else
            ok = ok and not MODS[kc_mod].isPressed
        end
        if not ok then
            break
        end
    end
    return ok
end


function MODS.match(keycode, kc_mod, state)
    if string.find(kc_mod, 'left') then
        keycode = 'left'..keycode
    end
    return keycode==kc_mod and getState(kc_mod)==state
end


function MODS.state()
    local M, S = 5, 12
    print('\t +-'..string.rep('-', M)..'-+-'..string.rep('-', S)..'-+-'..string.rep('-', S)..'-+-'..string.rep('-', S)..'-+')
    for _, mod in ipairs({'cmd', 'ctrl', 'alt', 'shift'}) do
        local L_state = getState('left'..mod)
        local state = getState(mod)
        local R_state = getState('right'..mod)
        print('\t | '
            ..mod..string.rep(' ', M-string.len(mod))..' | '
            ..L_state..string.rep(' ', S-string.len(L_state))..' | '
            ..state..string.rep(' ', S-string.len(state))..' | '
            ..R_state..string.rep(' ', S-string.len(R_state))..' |')
    end
    print('\t +-'..string.rep('-', M)..'-+-'..string.rep('-', S)..'-+-'..string.rep('-', S)..'-+-'..string.rep('-', S)..'-+')
end

return MODS
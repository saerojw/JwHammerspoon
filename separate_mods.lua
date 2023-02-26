local KC_MODS = {'cmd', 'ctrl', 'alt', 'shift', 'rightcmd', 'rightctrl', 'rightalt', 'rightshift',
                  cmd=1, ctrl=2, alt=3, shift=4, rightcmd=5, rightctrl=6, rightalt=7, rightshift=8}

local function reset()
    for _, kc_mod in ipairs(KC_MODS) do
        FLAGS[kc_mod].beenPressedAlone = false
    end
end

local function pressed(mod)
    return FLAGS[mod].isPressed
end

local function pressedAny(mods)
    local ret = false
    for _, mod in ipairs(mods) do
        ret = ret or FLAGS[mod].isPressed
    end
    return ret
end

local function pressedAll(mods)
    local ret = true
    for _, mod in ipairs(mods) do
        ret = ret and FLAGS[mod].isPressed
    end
    return ret
end

local function pressedExactly(mods)
    local ret = true
    for _, mod in ipairs(KC_MODS) do
        if mods[mod] then
        end
    end
end

local function get_state(kc_mod)
    local state = {[true] ={[true]='pressedAlone', [false]='pressed' },
                   [false]={[true]='tapped',       [false]='released'}}
    return state[FLAGS[kc_mod].isPressed][FLAGS[kc_mod].beenPressedAlone]
end

local function condition(keycode, kc_mod, state)
    return keycode==kc_mod and FLAGS.get_state(kc_mod)==state
end

local function update(event)
    local keycode = hs.keycodes.map[event:getKeyCode()]
    local flags = event:getFlags()

    if KC_MODS[keycode] then
        for _, mod in ipairs({'cmd', 'ctrl', 'alt', 'shift'}) do
            if flags[mod] then  -- mod is pressed
                if keycode==mod then
                    FLAGS[mod].isPressed = not FLAGS[mod].isPressed
                    FLAGS[mod].beenPressedAlone = not FLAGS['right'..mod].isPressed and flags:containExactly({mod})
                    FLAGS['right'..mod].beenPressedAlone = not FLAGS[mod].isPressed and flags:containExactly({mod})
                elseif keycode=='right'..mod then
                    FLAGS['right'..mod].isPressed = not FLAGS['right'..mod].isPressed
                    FLAGS[mod].beenPressedAlone = not FLAGS['right'..mod].isPressed and flags:containExactly({mod})
                    FLAGS['right'..mod].beenPressedAlone = not FLAGS[mod].isPressed and flags:containExactly({mod})
                else
                    FLAGS[mod].beenPressedAlone = false
                    FLAGS['right'..mod].beenPressedAlone = false
                end
            else
                FLAGS[mod].isPressed = false
                FLAGS['right'..mod].isPressed = false
            end
        end
    else
        FLAGS.reset()
    end
    return keycode
end


function separated_mods_FLAGS()
    FLAGS = {}
    for _, kc_mod in ipairs(KC_MODS) do
        FLAGS[kc_mod] = {isPressed=false, beenPressedAlone=false}
    end
    FLAGS.reset = reset
    FLAGS.pressed = pressed
    FLAGS.pressedAny = pressedAny
    FLAGS.pressedAll = pressedAll
    FLAGS.get_state = get_state
    FLAGS.update = update
    FLAGS.condition = condition
    FLAGS.keycodes = KC_MODS
    return FLAGS
end

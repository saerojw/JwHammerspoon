require "utils"

local function monitor(keycode, state)
    if MONITORING then
        if MONITORING['stroke'] then
            local pressed_mods = {}
            for _, kc_mod in ipairs(FLAGS.keycodes) do
                if FLAGS[kc_mod].isPressed then
                    table.insert(pressed_mods, kc_mod)
                end
            end
            check('\t\t\t', pressed_mods, keycode, state)
        end
        if MONITORING['mods'] then
            local M, S = 5, 12
            print('\t\t\t +-'..string.rep('-', M)..'-+-'..string.rep('-', S)..'-+-'..string.rep('-', S)..'-+')
            for _, mod in ipairs({'cmd', 'ctrl', 'alt', 'shift'}) do
                local L_state = FLAGS.get_state(mod)
                local R_state = FLAGS.get_state('right'..mod)
                print('\t\t\t | '
                    ..mod..string.rep(' ', M-string.len(mod))..' | '
                    ..L_state..string.rep(' ', S-string.len(L_state))..' | '
                    ..R_state..string.rep(' ', S-string.len(R_state))..' |')
            end
            print('\t\t\t +-'..string.rep('-', M)..'-+-'..string.rep('-', S)..'-+-'..string.rep('-', S)..'-+')
        end
    end
end


-- enter hammerspoon mode by shortcut
MONITORING = {['stroke']=false, ['mods']=false}
HS_MODE = {activated=false,
    hs.hotkey.new({}, 'r', hs.reload),
    hs.hotkey.new({}, 's', function() MONITORING['stroke']=not MONITORING['stroke'] end),
    hs.hotkey.new({}, 'm', function() MONITORING['mods']=not MONITORING['mods'] end)
}
hs.hotkey.bind({'cmd', 'ctrl', 'alt', 'shift'}, 'h',
    function() -- get only one stroke; escape script is in "keyUp_event"
        hs.application.launchOrFocus('Hammerspoon') -- open console
        hs.alert.show('      Hammerspoon mode\n'
                      ..'\n'
                      ..'R: reload\n'
                      ..'S: monitoring stroke event\n'
                      ..'M: monitoring modifier state', '')
        for _, hotkey in ipairs(HS_MODE) do
            hotkey:enable()
        end
        HS_MODE.activated = true
    end
)


require "remapping"
-- remap(src_mods, src_key, keyStroke([tgt_mods,] tgt_key))
-- remap_ex(src_mods, src_key, keyStroke, {[tgt_mods,] tgt_key}, modsConcat, options)
-- "remap" is operatig with a pressed hotkey and is repeated.
-- "remap_ex" extends "mods" to include combinations of "options" called "opt_mods".
-- "modsConcat" concatenates "opt_mods" with "mods" for "keyStroke".
remap({'ctrl'}, 'delete', keyStroke('forwarddelete'))
for arrw, src in pairs({up='i', left='j', down='k', right='l'}) do
    remap_ex({'ctrl'}, src, keyStroke, {arrw}, modsConcat, {'shift'})
end
ctrlb = remap_ex({'ctrl'}, 'b', keyStroke, {{'alt'}, 'left'}, modsConcat, {'shift'})
ctrlf = remap_ex({'ctrl'}, 'f', keyStroke, {{'alt'}, 'right'}, modsConcat, {'shift'})
remap_ex({'ctrl'}, 'p', keyStroke, {'pageup'}, modsConcat, {'shift'})
remap_ex({'ctrl'}, 'n', keyStroke, {'pagedown'}, modsConcat, {'shift'})

bypass = false
function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == "iTerm2") then
            ctrlb[1]:disable()
            ctrlf[1]:disable()
        else
            ctrlb[1]:enable()
            ctrlf[1]:enable()
        end
    end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()


-- 'capslock' is replaced with 'rightctrl' (System Preference > Keyboard > Keyboard > Modifier Keys).
-- disable 'Use the CapsLock key to switch to and from U.S.' (System Preference > Keyboard > Input Sources)
require "capslock"
hs.hotkey.bind({'shift'}, 'space', toggle_capslock_with_alert)


-- This code can distinguish between 'mod'(leftmod) and 'rightmod'.
require "language"
require "separate_mods"
FLAGS = separated_mods_FLAGS()
modChange_event = hs.eventtap.new(
    {hs.eventtap.event.types.flagsChanged},
    function (event)
        local keycode = FLAGS.update(event)
        monitor(keaycode)

        -- toggle Korean/English by tapping 'rightctrl'
        if FLAGS.condition(keycode, 'rightctrl', 'tapped') then
            toggle_language('Korean', 'English')
        end

        if FLAGS[keycode]~=nil and not FLAGS[keycode].isPressed then
            FLAGS.reset()
        end
    end
)
modChange_event:start()


keyDown_event = hs.eventtap.new(
    {hs.eventtap.event.types.keyDown},
    function (event)
        local keycode = FLAGS.update(event)
        monitor(keycode, 'pressed')

        -- If last key stroke is 'escape', change input source to English when ';' pressed.
        -- This should be useful for Korean vim users.
        if keycode==';' and LAST_STROKE=='escape' then
            set_language('English')
        end
    end
)
keyDown_event:start()


keyUp_event = hs.eventtap.new(
    {hs.eventtap.event.types.keyUp},
    function (event)
        local keycode = FLAGS.update(event)
        monitor(keycode, 'released')

        -- record last stroke
        LAST_STROKE = keycode
        -- escape from hammerspoon mode
        if HS_MODE.activated and keycode~='h' then
            for _, hotkey in ipairs(HS_MODE) do
                hotkey:disable()
            end
            hs.alert.closeAll()
            HS_MODE.activated = false
        end
    end
)
keyUp_event:start()
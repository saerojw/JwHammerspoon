require 'utils'

local function monitor(keycode, state)
    if MONITORING then
        if MONITORING['stroke'] then
            local pressed_mods = {}
            for _, kc_mod in ipairs(MODS.keycodes) do
                if MODS.pressed(kc_mod) then
                    table.insert(pressed_mods, kc_mod)
                end
            end
            check('\t', pressed_mods, keycode, state)
        end
        if MONITORING['mods'] then
            MODS.state()
        end
    end
end


-- enter hammerspoon mode by shortcut
hyper = {'cmd', 'ctrl', 'alt', 'shift'}
MONITORING = {['stroke']=false, ['mods']=false}
HS_MODE = {activated=false,
    hs.hotkey.new({}, 'r', hs.reload),
    hs.hotkey.new({}, 's', function() MONITORING['stroke']=not MONITORING['stroke'] end),
    hs.hotkey.new({}, 'm', function() MONITORING['mods']=not MONITORING['mods'] end)
}
hs.hotkey.bind(hyper, 'h',
    function() -- get only one stroke; escape script is in 'keyUp_event'
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

-- 'capslock' is replaced with 'rightctrl' (System Preference > Keyboard > Keyboard > Modifier Keys).
-- disable 'Use the CapsLock key to switch to and from U.S.' (System Preference > Keyboard > Input Sources)
require 'capslock'
require 'language'
require 'remapping' -- get hotkey condition table 'HK_CONDS'
hs.hotkey.setLogLevel(2.5) -- default=3
hs.fnutils.each({
-- {cond_kc_mods, src_key, tgt_kc_mods, tgt_key, expand_kc_mods}
        {{'ctrl'},      'delete', {},        'forwarddelete', {}},
        {{'rightctrl'}, '1',      {'shift'}, '1',             {}},
        {{'rightctrl'}, '2',      {'shift'}, '2',             {}},
        {{'rightctrl'}, '3',      {'shift'}, '3',             {}},
        {{'rightctrl'}, '4',      {'shift'}, '4',             {}},
        {{'rightctrl'}, '5',      {'shift'}, '5',             {}},
        {{'rightctrl'}, '6',      {'shift'}, '6',             {}},
        {{'rightctrl'}, '7',      {'shift'}, '7',             {}},
        {{'rightctrl'}, '8',      {'shift'}, '8',             {}},
        {{'rightctrl'}, '9',      {'shift'}, '9',             {}},
        {{'rightctrl'}, '0',      {'shift'}, '0',             {}},
        {{'rightctrl'}, '-',      {'shift'}, '-',             {}},
        {{'rightctrl'}, '=',      {'shift'}, '=',             {}},
        {{'ctrl'},      '[',      {'cmd'},   '[',             {}},
        {{'ctrl'},      ']',      {'cmd'},   ']',             {}},
        {{'rightctrl'}, '\\',     {'shift'}, '\\',            {}},
        {{'rightctrl'}, ';',      {'shift'}, ';',             {}},
        {{'rightctrl'}, "'",      {'shift'}, "'",             {}},
        {{'rightctrl'}, 'e',      {},        'end',           {'shift'}},
        {{'rightctrl'}, 'i',      {},        'up',            {'cmd', 'shift'}},
{{'alt', 'rightctrl'},  'i',      {'alt'},   'up',            {'shift'}},
        {{'rightctrl'}, 'p',      {},        'pageup',        {'shift'}},
        {{'rightctrl'}, 'a',      {},        'home',          {'shift'}},
        {{'rightctrl'}, 's',      {},        'space',         {}},
        {{'rightctrl'}, 'd',      {},        'forwarddelete', {}},
        {{'rightctrl'}, 'f',      {'alt'},   'right',         {'shift'}},
        {{'rightctrl'}, 'g',      {},        'return',        {}},
        {{'rightctrl'}, 'h',      {},        'delete',        {}},
        {{'rightctrl'}, 'j',      {},        'left',          {'cmd', 'shift'}},
{{'alt', 'rightctrl'},  'j',      {'alt'},   'left',          {'shift'}},
        {{'rightctrl'}, 'k',      {},        'down',          {'cmd', 'shift'}},
{{'alt', 'rightctrl'},  'k',      {'alt'},   'down',          {'shift'}},
        {{'rightctrl'}, 'l',      {},        'right',         {'cmd', 'shift'}},
{{'alt', 'rightctrl'},  'l',      {'alt'},   'right',         {'shift'}},
        {{'rightctrl'}, 'b',      {'alt'},   'left',          {'shift'}},
        {{'rightctrl'}, 'n',      {},        'pagedown',      {'shift'}},
-- {cond_kc_mods, src_key, pressedfn, releasedfn, repeatfn}
    {{},            'kana',  function() toggle_language('Korean', 'English') end},
    {{'leftctrl'},  'space', function() toggle_language('Korean', 'English') end},
    {{'shift'},     'space', toggle_capslock_with_alert}
    }, function(args) remap(table.unpack(args)) end
)


function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == 'iTerm2') then
            iTerm2 = true
        else
            iTerm2 = false
        end
    end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

function add_enable_cond(hotkey)
    local enable = true
    enable = enable and not (iTerm2 and (hotkey['idx']=='⌃B' or hotkey['idx']=='⌃F'))
    return enable
end


MODS = require('separate_mods')
t_LShiftDown = 0
modChange_event = hs.eventtap.new(
    {hs.eventtap.event.types.flagsChanged},
    function (event)
        local keycode = MODS.update(event)
        monitor(keaycode)

        if MODS.pressedExactly({"leftshift"}) then
            t_LShiftDown = hs.timer.absoluteTime()
        end
        local t_LShiftPressed = (hs.timer.absoluteTime() - t_LShiftDown) / 1000000 -- ms

        for hk_cond_id, hotkeys in pairs(HK_CONDS) do
            local hk_cond = {}
            for cond in string.gmatch(hk_cond_id, '[^%s]+') do
                table.insert(hk_cond, cond)
            end
            if MODS.pressedExactly(hk_cond) then
                for _, hotkey in ipairs(hotkeys) do
                    if hotkey.enabled then
                        if not add_enable_cond(hotkey) then
                            hotkey:disable()
                        end
                    elseif add_enable_cond(hotkey) then
                        hotkey:enable()
                    end
                end
            else
                for _, hotkey in ipairs(hotkeys) do
                    if hotkey.enabled then
                        hotkey:disable()
                    end
                end
            end
        end

        if MODS.match(keycode, 'rightctrl', 'tapped') then
            set_language('English')
        elseif MODS.match(keycode, 'leftshift', 'tapped') and t_LShiftPressed<200 then
            set_language('Korean')
        end
        if MODS[keycode]~=nil and not MODS.pressed(keycode) then
            MODS.reset()
        end
    end
)
modChange_event:start()


keyDown_event = hs.eventtap.new(
    {hs.eventtap.event.types.keyDown},
    function (event)
        local keycode = MODS.update(event)
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
        local keycode = MODS.update(event)
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

mouse_event = hs.eventtap.new(
    {hs.eventtap.event.types.leftMouseDown},
    function (event)
        if MODS.pressedAny(hyper) then
            MODS.reset()
        end
    end
)
mouse_event:start()
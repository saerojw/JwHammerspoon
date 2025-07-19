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
    {{'ctrl'},                  'delete',   {},                 'forwarddelete',    {}},
    {{'rightctrl'},             '9',        {'shift'},          '9',                {}},
    {{'rightctrl'},             '0',        {'shift'},          '0',                {}},
    {{'rightctrl'},             '[',        {'shift'},          '[',                {}},
    {{'rightctrl'},             ']',        {'shift'},          ']',                {}},
    {{'rightctrl'},             '\\',       {'shift'},          '\\',               {}},
    {{'rightctrl'},             ';',        {'shift'},          ';',                {}},
    {{'rightctrl'},             "'",        {'shift'},          "'",                {}},
    {{'rightctrl'},             ',',        {'shift'},          ',',                {}},
    {{'rightctrl'},             ".",        {'shift'},          ".",                {}},
    {{'rightctrl'},             'a',        {},                 'home',             {'shift'}},
    {{'alt'},                   'b',        {'alt'},            'left',             {'shift'}},
    {{'rightctrl'},             'd',        {},                 'forwarddelete',    {}},
    {{'alt'},                   'f',        {'alt'},            'right',            {'shift'}},
    {{'rightctrl'},             'g',        {'alt'},            'return',           {}},
    {{'rightctrl'},             'h',        {},                 'delete',           {}},
    {{'rightctrl'},             'i',        {},                 'up',               {'cmd', 'shift'}},
    {{'rightctrl', 'alt'},      'i',        {'alt'},            'up',               {}},
    {{'rightctrl'},             'j',        {},                 'left',             {'cmd', 'shift'}},
    {{'rightctrl', 'alt'},      'j',        {'alt'},            'left',             {'shift'}},
    {{'rightctrl'},             'k',        {},                 'down',             {'cmd', 'shift'}},
    {{'rightctrl', 'alt'},      'k',        {'alt'},            'down',             {}},
    {{'rightctrl'},             'l',        {},                 'right',            {'cmd', 'shift'}},
    {{'rightctrl', 'alt'},      'l',        {'alt'},            'right',            {'shift'}},
    {{'alt'},                   'n',        {},                 'pagedown',         {'shift'}},
    {{'rightctrl', 'alt'},      'n',        {'alt'},            'down',             {}},
    {{'rightctrl', 'shift'},    'n',        {'shift'},          'down',             {}},
    {{'alt'},                   'p',        {},                 'pageup',           {'shift'}},
    {{'rightctrl', 'alt'},      'p',        {'alt'},            'up',               {}},
    {{'rightctrl', 'shift'},    'p',        {'shift'},          'up',               {}},
    {{'rightctrl'},             'r',        {},                 'return',           {'cmd', 'alt', 'shift'}},
    {{'rightctrl', 'alt'},      'u',        {'alt'},            'up',               {}},
    {{'leftcmd'},               'b',        {'ctrl'},           'b',                {}},
-- {cond_kc_mods, src_key, pressedfn, releasedfn, repeatfn}
    {{},            'kana',     function() toggle_language('Korean', 'English') end},
    {{'leftctrl'},  'space',    function() toggle_language('Korean', 'English') end},
    {{'shift'},     'space',    toggle_capslock_with_alert}
    }, function(args) remap(table.unpack(args)) end
)


function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        debug_print("App event:", appName)
        iTerm2 = (appName == 'iTerm2')
        MSoffice = (appName == 'Microsoft Word' or appName == 'Microsoft Excel' or appName == 'Microsoft PowerPoint')
        vscode = (appName == 'Code' or appName == 'Cursor')
    end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

function disable_cond(hotkey)
    local function hotkey_cond(hotkey, idx_table)
        local cond = false
        for _, idx in ipairs(idx_table) do
            cond = cond or (hotkey['idx'] == idx)
        end
        return cond
    end
    --
    local disable = false
    if hotkey_cond(hotkey, {'⌃A', '⌃E'}) then
        disable = not (MSoffice or vscode)
    elseif hotkey_cond(hotkey, {'⌘B'}) then
        disable = not iTerm2
    end
    return disable
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
                    if disable_cond(hotkey) then
                        if hotkey.enabled then
                            hotkey:disable()
                        end
                    elseif not hotkey.enabled then
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
            toggle_language('Korean', 'English')
        elseif MODS.match(keycode, 'rightshift', 'tapped') then
            set_language('Korean')
        elseif MODS.match(keycode, 'leftshift', 'tapped') and t_LShiftPressed<200 then
            set_language('English')
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
        -- Sometimes, ^a and ^e not working when language is Korean
        elseif (keycode=='a' or keycode=='e') and is_language('Korean') and MODS.pressedExactly({"rightctrl"}) then
            set_language('English')
            ae_toggle_lan = true
        end
    end
)
keyDown_event:start()


keyUp_event = hs.eventtap.new(
    {hs.eventtap.event.types.keyUp},
    function (event)
        local keycode = MODS.update(event)
        monitor(keycode, 'released')

        -- Record last stroke
        LAST_STROKE = keycode
        -- Escape from hammerspoon mode
        if HS_MODE.activated and keycode~='h' then
            for _, hotkey in ipairs(HS_MODE) do
                hotkey:disable()
            end
            hs.alert.closeAll()
            HS_MODE.activated = false
        -- Restore language setting for ^a and ^e
        elseif (keycode=='a' or keycode=='e') and ae_toggle_lan then
            set_language('Korean')
            ae_toggle_lan = false
        end
    end
)
keyUp_event:start()


-- TODO feature
-- CursorCorral = require('cursor_corral')
leftMouseDown = false
rightMouseDown = false
mouse_event = hs.eventtap.new(
    {hs.eventtap.event.types.leftMouseDown,
     hs.eventtap.event.types.rightMouseDown,
     hs.eventtap.event.types.leftMouseUp,
     hs.eventtap.event.types.rightMouseUp},
    function (event)
        local button = event:getProperty(hs.eventtap.event.properties['mouseEventButtonNumber'])

        if event:getType() == hs.eventtap.event.types.leftMouseDown then
            leftMouseDown = true
        elseif event:getType() == hs.eventtap.event.types.rightMouseDown then
            rightMouseDown = true
        elseif event:getType() == hs.eventtap.event.types.leftMouseUp then
            leftMouseDown = false
        elseif event:getType() == hs.eventtap.event.types.rightMouseUp then
            rightMouseDown = false
        end

        if leftMouseDown and rightMouseDown then
            -- if not hs.application.launchOrFocus("logioptionsplus") then
            --     hs.alert.show("Fail to run Logi Options+")
            -- end

            -- if CursorCorral.isEnabled() then
            --     CursorCorralEnabled = CursorCorral.disable()
            -- else
            --     CursorCorralEnabled = CursorCorral.enable()
            -- end

            leftMouseDown = false
            rightMouseDown = false
            return true
        end
    end
)
mouse_event:start()
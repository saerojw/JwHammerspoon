function toggle_capslock_with_alert()
    local translate = {[true]='On', [false]='Off'}
    local state = hs.hid.capslock.toggle()
    hs.alert.closeAll()
    hs.alert.show('CapsLock '..translate[state], 1)
end
local language = {["Korean"]="com.apple.inputmethod.Korean.2SetKorean",
                  ["English"]="com.apple.keylayout.ABC"}

function is_language(lan)
    return hs.keycodes.currentSourceID()==language[lan]
end


function set_language(lan)
    hs.keycodes.currentSourceID(language[lan])
end


function toggle_language(lan1, lan2)
    if hs.keycodes.currentSourceID()==language[lan1] then
        hs.keycodes.currentSourceID(language[lan2])
    else
        hs.keycodes.currentSourceID(language[lan1])
    end
end
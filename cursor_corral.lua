local function clamp(x, lo, hi) return math.max(lo, math.min(x, hi)) end

local margin = 10
function getCursorBounds()
    local bounds = {}
    -- local screens = hs.screen.allScreens()
    for i, screen in ipairs(hs.screen.allScreens()) do
        local frame = screen:fullFrame()
        if i == 1 then
            bounds.x = frame.x
            bounds.y = frame.y
            bounds.X = frame.x + frame.w
            bounds.Y = frame.y + frame.h
        else
            bounds.x = math.min(bounds.x, frame.x)
            bounds.y = math.min(bounds.y, frame.y)
            bounds.X = math.max(bounds.X, frame.x + frame.w)
            bounds.Y = math.max(bounds.Y, frame.y + frame.h)
        end
    end
    return {x = bounds.x + margin, y = bounds.y + margin, X = bounds.X - margin, Y = bounds.Y - margin}
end
local cursorBounds = getCursorBounds()

function updateCursorBounds()
    cursorBounds = getCursorBounds()
    print("\n"..cursorBounds.x.." "..cursorBounds.y.."    "..cursorBounds.X.." "..cursorBounds.Y)
end
local screenWatcher = hs.screen.watcher.new(updateCursorBounds)
screenWatcher:start()

local near_bound = false
local cursorWatcher = hs.eventtap.new(
    {hs.eventtap.event.types.mouseMoved},
    function(event)
        local curr_position = hs.mouse.absolutePosition()
        if near_bound then
            hs.focus()
            hs.mouse.absolutePosition({x = clamp(curr_position.x, cursorBounds.x, cursorBounds.X),
                                       y = clamp(curr_position.y, cursorBounds.y, cursorBounds.Y)})
        end
        near_bound = (  curr_position.x < cursorBounds.x or cursorBounds.X < curr_position.x
                     or curr_position.y < cursorBounds.y or cursorBounds.Y < curr_position.y)
        return false  -- 다른 이벤트 처리기에 이벤트를 전달하지 않음
    end
)
cursorWatcher:stop()

CursorCorral = {}
function CursorCorral.isEnabled()
    return cursorWatcher:isEnabled()
end
function CursorCorral.enable()
    cursorWatcher:start()
    hs.alert.show("CursorCorral On")
    return true
end
function CursorCorral.disable()
    cursorWatcher:stop()
    hs.alert.show("CursorCorral Off")
    return false
end

return CursorCorral

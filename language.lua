local language = {['Korean']='com.apple.inputmethod.Korean.2SetKorean',
                  ['English']='com.apple.keylayout.ABC'}


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

local boxes = {}
local box_height = 23
local box_alpha = 0.35
local GREEN = hs.drawing.color.osx_green

-- 입력소스 변경 이벤트에 이벤트 리스너를 달아준다
hs.keycodes.inputSourceChanged(function()
    aurora_disable()
    if hs.keycodes.currentSourceID() == language['Korean'] then
        aurora_enable()
    end
end)

function aurora_enable()
    reset_boxes()
    hs.fnutils.each(hs.screen.allScreens(), function(scr)
        local frame = scr:fullFrame()

        local box = newBox()
        draw_rectangle(box, frame.x, frame.y, frame.w, box_height, GREEN)
        table.insert(boxes, box)

        local box2 = newBox()
        draw_rectangle(box2, frame.x, frame.y, frame.w, box_height, GREEN)
        table.insert(boxes, box2)
    end)
end

function aurora_disable()
    hs.fnutils.each(boxes, function(box)
        if box ~= nil then
            box:delete()
        end
    end)
    reset_boxes()
end

function newBox()
    return hs.drawing.rectangle(hs.geometry.rect(0,0,0,0))
end

function reset_boxes()
    boxes = {}
end

function draw_rectangle(target_draw, x, y, width, height, fill_color)
  -- 그릴 영역 크기를 잡는다
  target_draw:setSize(hs.geometry.rect(x, y, width, height))
  -- 그릴 영역의 위치를 잡는다
  target_draw:setTopLeft(hs.geometry.point(x, y))

  target_draw:setFillColor(fill_color)
  target_draw:setFill(true)
  target_draw:setAlpha(box_alpha)
  target_draw:setLevel(hs.drawing.windowLevels.overlay)
  target_draw:setStroke(false)
  target_draw:setBehavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
  target_draw:show()
end
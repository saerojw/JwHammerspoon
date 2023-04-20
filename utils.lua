-- table utils

function copy(t)
    local ret = {}
    for k, v in pairs(t) do
        if type(v)=='table' then
            ret[k] = copy(v)
        else
            ret[k] = v
        end
    end
    return ret
end


function concat(...)
    local tables = {...}
    local ret = {}
    for _, t in ipairs(tables) do
        assert(type(t)=='table')
        for _, v in ipairs(t) do
            table.insert(ret, v)
        end
    end
    return ret
end


-- debug utils
function str(arg)
    local ret = ''
    if type(arg)=='table' then
        local cnt, icnt = 1, 1
        ret = ret..'{'
        for k, v in pairs(arg) do
            if cnt>1 then
                ret = ret..', '
            end
            cnt = cnt+1
            if type(k)=='number' and math.type(k)=='integer' and k==icnt then
                icnt = icnt+1
            elseif type(k)=='string' then
                ret = ret.."['"..str(k).."']="
            else
                ret = ret..'['..str(k)..']='
            end
            if type(v)=='string' then
                ret = ret.."'"..str(v).."'"
            else
                ret = ret..str(v)
            end
        end
        ret = ret..'}'
    else
        ret = ret..tostring(arg)
    end
    return ret
end


function check(...)
    local args = {...}
    local log = ''
    for i, arg in pairs(args) do
        if i>1 then
            log = log..' '..str(arg)
        else
            log = log..str(arg)
        end
    end
    print(log)
end
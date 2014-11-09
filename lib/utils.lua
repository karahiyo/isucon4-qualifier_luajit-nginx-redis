--- util
function tableToString( t )
    if t[1] then
        ngx.log(ngx.ERR, "array")
        return arrayToString( t )
    else
        ngx.log(ngx.ERR, "dict")
        return dictionaryToString( t )
    end
end
function arrayToString( t )
    local s = { "{" }
    local i = 2
    for j = 1, #t do
        s[i] = valueToString( t[j] )
        s[i+1] = ","
        i = i + 2
    end
    s[i-1] = "}"
    return table.concat( s )
end
function dictionaryToString( t )
    local s = { "{" }
    local i = 2
    for key, val in pairs( t ) do
        s[i] = key
        s[i+1] = "="
        s[i+2] = valueToString( val )
        s[i+3] = ","
        i = i + 4
    end
    s[i-1] = "}"
    return table.concat( s )
end
function valueToString( val )
    if type( val ) == "string" then
        return [["]] .. val .. [["]]
    elseif type( val ) == "table" then
        return tableToString( val )
    elseif type( val ) == "number" or type(val) == "boolean" then
        return tostring( val )
    else
        error( "the table contains thread, function or userdata value." )
    end
end



function redis_key_user(login)
    return "isu4:user:"..login
end
function redis_key_ip(ip)
    return "isu4:ip:"..ip
end
function redis_key_last(login)
    return "isu4:last:"..login
end
function redis_key_next_last(login)
    return "ise4:next_last:"..login
end


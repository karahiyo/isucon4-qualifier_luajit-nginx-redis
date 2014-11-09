local util = {}

function util:redis_key_user(login)
    return "isu4:user:"..login
end
function util:redis_key_ip(ip)
    return "isu4:ip:"..ip
end
function util:redis_key_last(login)
    return "isu4:last:"..login
end
function util:redis_key_next_last(login)
    return "ise4:next_last:"..login
end

return util

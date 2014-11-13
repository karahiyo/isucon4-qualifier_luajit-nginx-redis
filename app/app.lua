local app = {}

function app:redis_key_user(login)
    return "isu4:user:"..login
end
function app:redis_key_user_fail(login)
    return "isu4:user_fail:"..login
end
function app:redis_key_ip(ip)
    return "isu4:ip:"..ip
end
function app:redis_key_last(login)
    return "isu4:last:"..login
end
function app:redis_key_next_last(login)
    return "ise4:next_last:"..login
end
function app:get_user(login)
    local res = redis:hgetall(app:redis_key_user(login))
    if not res then
        return
    end
    return redis:array_to_hash(res)
end
function app:ip_banned()
    local kip = app:redis_key_ip(ngx.var.remote_addr)
    local fail_count = tonumber(redis:get(kip))
    if not fail_count then
        return false
    end
    return fail_count >= conf.user_lock_threshold
end
function app:user_locked(login)
    local kuser_fail = app:redis_key_user_fail(login)
    local fail_count = tonumber(redis:get(kuser_fail))
    if not fail_count then
        return false
    end
    return fail_count >= conf.ip_ban_threshold
end

return app


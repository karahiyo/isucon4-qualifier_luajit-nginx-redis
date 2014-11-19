local app = {
    redis = nil
}

function app:start(_host,_port)
    self.redis = resty_redis:new()

    -- timeout: 1s
    self.redis:set_timeout(1000)

    local ok, err = self.redis:connect(_host, _port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to redis: ", err)
        return ngx.exit(500)
    end
end

function app:key_user(login)
    return "isu4:user:"..login
end
function app:key_user_fail(login)
    return "isu4:user_fail:"..login
end
function app:key_ip(ip)
    return "isu4:ip:"..ip
end
function app:key_last(login)
    return "isu4:last:"..login
end
function app:key_next_last(login)
    return "ise4:next_last:"..login
end
function app:get_user(login)
    local res = self.redis:hgetall(self:key_user(login))
    if not res then
        return
    end
    return self.redis:array_to_hash(res)
end
function app:ip_banned()
    local kip = self:key_ip(ngx.var.remote_addr)
    local fail_count = tonumber(self.redis:get(kip))
    if not fail_count then
        return false
    end
    return fail_count >= conf.user_lock_threshold
end
function app:user_locked(login)
    local kuser_fail = self:key_user_fail(login)
    local fail_count = tonumber(self.redis:get(kuser_fail))
    if not fail_count then
        return false
    end
    return fail_count >= conf.ip_ban_threshold
end

function app:attempt_login(login, password)
    if not login or not password then
        return _, "Wrong username or password"
    end
    local user = self:get_user(login)

    if self:ip_banned() then
        ngx.log(ngx.ERR, "** ip bunned")
        return _, "You're banned."
    end
    if self:user_locked(login) then
        ngx.log(ngx.ERR, "** user locked")
        return _, "This account is locked."
    end

    local kip  = self:key_ip(ngx.var.remote_addr)
    local kuser_fail = self:key_user_fail(login)
    if user and user.password == password then
        local klast = self:key_last(login)
        local knext_last = self:key_next_last(login)
        pcall(self.redis:rename(knext_last, klast))
        self.redis:hmset(knext_last, {at=ngx.localtime(), ip=ngx.var.remote_addr })
        self.redis:mset(kip, 0, kuser_fail, 0)
        return {login = user.login}
    else
        self.redis:incr(kip)
        self.redis:incr(kuser_fail)
        ngx.log(ngx.ERR, "** bunned ip count: ", self.redis:get(kip))
        ngx.log(ngx.ERR, "** locked user count: ", self.redis:get(kuser_fail))
        return _, "Wrong username or password"
    end
end

return app

